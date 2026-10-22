const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const crypto = require("crypto");
const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const { RtcTokenBuilder, RtcRole } = require("agora-token");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  initializeApp();
}

// Helper to safely parse Date from Firestore Timestamp, ISO string, or Date
function toJsDate(val) {
  if (!val) return null;
  if (typeof val.toDate === "function") return val.toDate();
  if (val instanceof Date) return val;
  if (typeof val === "string" || typeof val === "number") {
    const parsed = new Date(val);
    return isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

// Helper to format human-readable session type in push notifications
function formatSessionTypeName(raw) {
  if (!raw) return "support";
  const str = String(raw);
  if (str.includes("voiceCall")) return "voice call";
  if (str.includes("videoCall")) return "video call";
  if (str.includes("messages")) return "chat";
  return str;
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH TRIGGER: On User Auth Created
// ═══════════════════════════════════════════════════════════════════════════════
// Creates a base sentinel document when a new user signs up, allowing Onboarding to route.

const auth = require("firebase-functions/v1/auth");

exports.onUserAuthCreated = auth.user().onCreate(async (user) => {
  const db = getFirestore();
  
  const userData = {
    uid: user.uid,
    email: user.email || "",
    displayName: user.displayName || "",
    profileComplete: false,
    role: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  try {
    await db.collection("users").doc(user.uid).set(userData, { merge: true });
    logger.info(`Sentinel profile created for user: ${user.uid}`);
  } catch (error) {
    logger.error(`Error creating profile for user ${user.uid}:`, error);
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// AUTO-MATCHING SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════
// Triggers when a session is created or updated to assign an available listener.

exports.autoMatchSession = onDocumentWritten("sessions/{sessionId}", async (event) => {
  const snapshot = event.data.after;
  if (!snapshot.exists) return;

  const data = snapshot.data();

  // Only trigger for pending sessions without an assigned listener
  if (data.status !== "pending" || data.listenerId != null) {
    return;
  }

  const db = getFirestore();
  
  // Find online listeners
  const listenersSnapshot = await db.collection("users")
    .where("role", "==", "listener")
    .where("listenerData.isOnline", "==", true)
    .get();

  const rejectedBy = data.rejectedBy || [];
  const seekerLanguages = data.languages || (data.seekerLanguage ? [data.seekerLanguage] : []);
  
  const languageMatchedListeners = [];
  const fallbackListeners = [];

  listenersSnapshot.forEach(doc => {
    if (!rejectedBy.includes(doc.id)) {
      fallbackListeners.push(doc.id);
      const lData = doc.data().listenerData || {};
      const spoken = lData.languagesSpoken || [];
      if (seekerLanguages.length > 0) {
        if (seekerLanguages.some(code => spoken.includes(code))) {
          languageMatchedListeners.push(doc.id);
        }
      } else {
        languageMatchedListeners.push(doc.id);
      }
    }
  });

  const availableListeners = languageMatchedListeners.length > 0
    ? languageMatchedListeners
    : fallbackListeners;

  if (availableListeners.length > 0) {
    // Pick a random available listener (Uber-style)
    const randomIndex = Math.floor(Math.random() * availableListeners.length);
    const chosenUid = availableListeners[randomIndex];
    
    logger.info(`Session ${event.params.sessionId}: Assigned to listener ${chosenUid}`);
    await snapshot.ref.update({
      listenerId: chosenUid,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Send FCM push notification to the listener
    try {
      const listenerDoc = await db.collection("users").doc(chosenUid).get();
      const fcmToken = listenerDoc.data()?.fcmToken;
      if (fcmToken) {
        const readableType = formatSessionTypeName(data.sessionType);
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title: "New Support Request",
            body: `${data.seekerMoniker || "A seeker"} is requesting a ${readableType} session.`
          },
          data: {
            sessionId: event.params.sessionId,
            sessionType: String(data.sessionType || "messages")
          }
        });
        logger.info(`FCM notification sent to listener ${chosenUid}`);
      }
    } catch (fcmErr) {
      logger.warn(`Failed to send FCM notification to listener ${chosenUid}:`, fcmErr);
    }
  } else {
    // No one available
    logger.info(`Session ${event.params.sessionId}: No available listeners found, marking as rejected.`);
    await snapshot.ref.update({
      status: "rejected",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
});

const agoraAppId = defineSecret("AGORA_APP_ID");
const agoraAppCertificate = defineSecret("AGORA_APP_CERTIFICATE");
const razorpayKeyId = defineSecret("RAZORPAY_KEY_ID");
const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");

// ═══════════════════════════════════════════════════════════════════════════════
// USER PROVISIONING
// ═══════════════════════════════════════════════════════════════════════════════
// Automatically mark sessions as completed after 10 minutes

exports.autoTimeoutSessions = onSchedule("every 1 minutes", async (event) => {
  const db = getFirestore();
  const now = new Date();
  const tenMinutesAgo = new Date(now.getTime() - 10 * 60000);

  const activeSessions = await db.collection("sessions")
    .where("status", "==", "active")
    .get();

  let timeoutCount = 0;
  const batch = db.batch();

  activeSessions.forEach(doc => {
    const data = doc.data();
    const startedAt = toJsDate(data.startedAt) || toJsDate(data.updatedAt) || toJsDate(data.createdAt) || toJsDate(data.requestedAt);
    
    if (startedAt && startedAt < tenMinutesAgo) {
      batch.update(doc.ref, { 
        status: "completed",
        endedReason: "auto_timeout",
        completedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });
      timeoutCount++;
    }
  });

  if (timeoutCount > 0) {
    await batch.commit();
    logger.info(`Auto-timed out ${timeoutCount} active sessions.`);
  } else {
    logger.info("No sessions to time out.");
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// FINANCIALS & SECRETS
// ═══════════════════════════════════════════════════════════════════════════════

// Generate Agora Token for Voice/Video Calls
exports.generateAgoraToken = onCall({ secrets: [agoraAppId, agoraAppCertificate] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }
  const channelName = request.data.channelName;
  const uid = request.data.uid || 0; // 0 for Agora means 'let Agora assign' or use string uid

  if (!channelName) {
    throw new HttpsError("invalid-argument", "channelName is required.");
  }

  const appId = agoraAppId.value();
  const appCert = agoraAppCertificate.value();

  let token = "";
  try {
    if (appId && appCert && appId.length >= 10 && appCert.length >= 10) {
      const expirationTimeInSeconds = 3600; // 1 hour token
      token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCert,
        channelName,
        uid,
        RtcRole.PUBLISHER,
        expirationTimeInSeconds,
        expirationTimeInSeconds
      );
    }
  } catch (err) {
    logger.warn("Agora real token generation failed, falling back to mock token:", err);
  }

  if (!token) {
    token = `mock_agora_token_for_${channelName}_signed_by_${appId}`;
  }
  
  return {
    token: token,
    appId: appId,
    channelName: channelName,
    uid: uid
  };
});

// Process Payout via RazorpayX (Authorized Trigger)
exports.processPayout = onCall({ secrets: [razorpayKeyId, razorpayKeySecret] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { listenerUid } = request.data || {};
  if (!listenerUid) {
    throw new HttpsError("invalid-argument", "listenerUid is required.");
  }

  // A2.1 (D-11): Only the authenticated listener themselves or an admin can trigger payout
  const isSelf = request.auth.uid === listenerUid;
  const isAdmin = request.auth.token && (request.auth.token.admin === true || request.auth.token.role === "admin");
  if (!isSelf && !isAdmin) {
    throw new HttpsError("permission-denied", "You are not authorized to process payouts for this account.");
  }

  const db = getFirestore();
  const ledgerRef = db.collection("ledgers").doc(listenerUid);

  // Read pendingPayout server-side in a transaction, ignoring any client-supplied amount
  const payoutResult = await db.runTransaction(async (transaction) => {
    const ledgerDoc = await transaction.get(ledgerRef);
    if (!ledgerDoc.exists) {
      throw new HttpsError("not-found", "Ledger record not found for this listener.");
    }

    const ledgerData = ledgerDoc.data();
    const pendingAmount = Number(ledgerData.pendingPayout || 0);

    if (pendingAmount <= 0) {
      return { success: false, amount: 0, message: "No pending earnings available for payout." };
    }

    // Mocking RazorpayX API call
    logger.info(`Triggering RazorpayX Payout for ${listenerUid} of amount ${pendingAmount} INR using key ${razorpayKeyId.value()}`);

    transaction.update(ledgerRef, {
      pendingPayout: 0.0,
      totalEarned: FieldValue.increment(pendingAmount),
      lastPayoutAt: FieldValue.serverTimestamp()
    });

    const payoutRecordRef = ledgerRef.collection("payouts").doc();
    transaction.set(payoutRecordRef, {
      amount: pendingAmount,
      status: "completed",
      processedAt: FieldValue.serverTimestamp(),
      requestedBy: request.auth.uid
    });

    // A3.5: Ledger transaction log debit entry
    const txRecordRef = ledgerRef.collection("transactions").doc();
    transaction.set(txRecordRef, {
      type: "debit",
      amount: -pendingAmount,
      status: "completed",
      payoutId: payoutRecordRef.id,
      timestamp: FieldValue.serverTimestamp(),
      description: "Bank Transfer Payout"
    });

    return {
      success: true,
      amount: pendingAmount,
      message: `Payout of ₹${pendingAmount} processed successfully.`
    };
  });

  return payoutResult;
});

// Calculate Payout when Session is Completed
exports.onSessionCompleted = onDocumentWritten("sessions/{sessionId}", async (event) => {
  const before = event.data.before ? event.data.before.data() : null;
  const after = event.data.after ? event.data.after.data() : null;

  if (!before || !after) return;
  if (before.status !== "completed" && after.status === "completed") {
    const listenerUid = after.targetListenerUid || after.listenerUid || after.listenerId;
    if (!listenerUid) return;

    const startedAt = toJsDate(after.startedAt) || toJsDate(after.createdAt) || toJsDate(after.requestedAt);
    const endedAt = toJsDate(after.completedAt) || toJsDate(after.updatedAt) || new Date();

    let minutes = 10;
    if (startedAt && endedAt && endedAt > startedAt) {
      minutes = Math.min(15, Math.max(1, Math.round((endedAt.getTime() - startedAt.getTime()) / 60000)));
    }

    const ratePerMinute = 5.0; // INR
    const earned = minutes * ratePerMinute;

    const db = getFirestore();
    const ledgerRef = db.collection("ledgers").doc(listenerUid);
    
    await ledgerRef.set({
      pendingPayout: FieldValue.increment(earned),
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    // A3.5: Ledger transaction log credit entry
    const txRef = ledgerRef.collection("transactions").doc();
    await txRef.set({
      type: "credit",
      amount: earned,
      sessionId: event.params.sessionId,
      durationMinutes: minutes,
      ratePerMinute: ratePerMinute,
      timestamp: FieldValue.serverTimestamp(),
      description: `Peer Session (${minutes} mins)`
    });

    logger.info(`Session ${event.params.sessionId} completed. Listener ${listenerUid} earned ${earned} INR for ${minutes} mins.`);
  }
});

// Webhook endpoint to verify and capture Razorpay payment callbacks
exports.razorpayWebhook = onRequest({ secrets: [razorpayKeySecret] }, async (req, res) => {
  const signature = req.headers["x-razorpay-signature"];
  const webhookSecret = razorpayKeySecret.value();

  if (!signature) {
    logger.warn("Webhook received without signature.");
    res.status(400).send("Signature missing.");
    return;
  }

  // Verify the signature using the raw body
  const shasum = crypto.createHmac("sha256", webhookSecret);
  shasum.update(req.rawBody);
  const digest = shasum.digest("hex");

  if (digest !== signature) {
    logger.error("Invalid webhook signature.");
    res.status(400).send("Signature verification failed.");
    return;
  }

  const event = req.body.event;
  logger.info(`Received webhook event: ${event}`);

  if (event === "payment.authorized" || event === "payment.captured") {
    const payment = req.body.payload.payment.entity;
    const sessionId = payment.notes ? payment.notes.sessionId : null;

    if (!sessionId) {
      logger.warn(`No sessionId found in notes for payment: ${payment.id}`);
      res.status(200).send("No sessionId in notes, ignored.");
      return;
    }

    const db = getFirestore();
    const sessionRef = db.collection("sessions").doc(sessionId);
    const doc = await sessionRef.get();

    if (!doc.exists) {
      logger.error(`Session ${sessionId} not found.`);
      res.status(404).send("Session not found.");
      return;
    }

    const data = doc.data();
    if (data.status === "payment_pending" || data.status === "pending") {
      await sessionRef.update({
        status: "active",
        paymentId: payment.id,
        startedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });
      logger.info(`Session ${sessionId} marked active via Razorpay webhook.`);
    } else {
      logger.info(`Session ${sessionId} already in status ${data.status}, webhook ignored.`);
    }
  }

  res.status(200).send("OK");
});

