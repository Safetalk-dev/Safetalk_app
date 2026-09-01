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

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH TRIGGER: On User Auth Created
// ═══════════════════════════════════════════════════════════════════════════════
// Creates a base Firestore document when a new user signs up.

const auth = require("firebase-functions/v1/auth");

exports.onUserAuthCreated = auth.user().onCreate(async (user) => {
  const db = getFirestore();
  
  const userData = {
    uid: user.uid,
    role: "user", // Default role
    createdAt: new Date().toISOString(),
  };

  try {
    await db.collection("users").doc(user.uid).set(userData, { merge: true });
    logger.info(`Base profile created for user: ${user.uid}`);
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
  
  const availableListeners = [];
  listenersSnapshot.forEach(doc => {
    if (!rejectedBy.includes(doc.id)) {
      availableListeners.push(doc.id);
    }
  });

  if (availableListeners.length > 0) {
    // Pick a random available listener (Uber-style)
    const randomIndex = Math.floor(Math.random() * availableListeners.length);
    const chosenUid = availableListeners[randomIndex];
    
    logger.info(`Session ${event.params.sessionId}: Assigned to listener ${chosenUid}`);
    await snapshot.ref.update({ listenerId: chosenUid });

    // Send FCM push notification to the listener
    try {
      const listenerDoc = await db.collection("users").doc(chosenUid).get();
      const fcmToken = listenerDoc.data()?.fcmToken;
      if (fcmToken) {
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title: "New Support Request",
            body: `${data.seekerMoniker || "A seeker"} is requesting a ${data.sessionType || "support"} session.`
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
    await snapshot.ref.update({ status: "rejected" });
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
    // Use updatedAt or createdAt to simulate the 10-minute check
    // In production, we would use a dedicated 'startedAt' field set when status becomes active
    const startedAt = data.updatedAt ? new Date(data.updatedAt) : new Date(data.createdAt);
    
    if (startedAt < tenMinutesAgo) {
      batch.update(doc.ref, { 
        status: "completed",
        endedReason: "auto_timeout",
        updatedAt: now.toISOString()
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

// Process Payout via RazorpayX (Manual Review Trigger)
exports.processPayout = onCall({ secrets: [razorpayKeyId, razorpayKeySecret] }, async (request) => {
  // Only admins or automated triggers post-review should call this in production.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { listenerUid, amount } = request.data;
  if (!listenerUid || !amount) {
    throw new HttpsError("invalid-argument", "listenerUid and amount are required.");
  }

  // Mocking RazorpayX API call
  logger.info(`Triggering RazorpayX Payout for ${listenerUid} of amount ${amount} INR using key ${razorpayKeyId.value()}`);
  
  // Update internal ledger
  const db = getFirestore();
  const ledgerRef = db.collection("ledgers").doc(listenerUid);
  
  await ledgerRef.set({
    pendingPayout: 0.0,
    totalEarned: FieldValue.increment(amount),
    lastPayoutAt: new Date().toISOString()
  }, { merge: true });

  return {
    success: true,
    message: "Payout processed successfully."
  };
});

// Calculate Payout when Session is Completed
exports.onSessionCompleted = onDocumentWritten("sessions/{sessionId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (!before || !after) return;
  if (before.status !== "completed" && after.status === "completed") {
    const listenerUid = after.targetListenerUid || after.listenerUid || after.listenerId;
    if (!listenerUid) return;

    const startedAt = after.createdAt ? new Date(after.createdAt) : null;
    const endedAt = after.updatedAt ? new Date(after.updatedAt) : new Date();

    let minutes = 0;
    if (startedAt) {
      minutes = Math.max(1, Math.round((endedAt - startedAt) / 60000));
    } else {
      minutes = 10; // Fallback 10 minutes
    }

    const ratePerMinute = 5.0; // INR
    const earned = minutes * ratePerMinute;

    const db = getFirestore();
    const ledgerRef = db.collection("ledgers").doc(listenerUid);
    
    await ledgerRef.set({
      pendingPayout: FieldValue.increment(earned)
    }, { merge: true });

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
        updatedAt: new Date().toISOString()
      });
      logger.info(`Session ${sessionId} marked active via Razorpay webhook.`);
    } else {
      logger.info(`Session ${sessionId} already in status ${data.status}, webhook ignored.`);
    }
  }

  res.status(200).send("OK");
});

