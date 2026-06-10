const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { beforeUserCreated } = require("firebase-functions/v2/identity");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

initializeApp();

// ═══════════════════════════════════════════════════════════════════════════════
// BLOCKING FUNCTION: Before User Created
// ═══════════════════════════════════════════════════════════════════════════════
// This runs BEFORE a new user account is finalized in Firebase Auth.
// Use it for validation, enrichment, or blocking unwanted signups.

exports.beforeUserCreated = beforeUserCreated((event) => {
  const user = event.data;

  logger.info("New user signing up:", {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    provider: user.providerData?.[0]?.providerId ?? "unknown",
  });

  // Example: Block signups from disposable email domains
  // const blockedDomains = ["tempmail.com", "throwaway.email"];
  // const domain = user.email?.split("@")[1];
  // if (blockedDomains.includes(domain)) {
  //   throw new HttpsError("invalid-argument", "Disposable emails are not allowed.");
  // }

  // Return custom claims or session data if needed
  return {
    customClaims: {
      role: "user", // Default role for new signups
      createdVia: "safetalk",
    },
  };
});

// ═══════════════════════════════════════════════════════════════════════════════
// FIRESTORE TRIGGER: On User Profile Created (for future use)
// ═══════════════════════════════════════════════════════════════════════════════
// Uncomment when you add Firestore user profiles.

// exports.onUserProfileCreated = onDocumentCreated("users/{userId}", (event) => {
//   const snapshot = event.data;
//   if (!snapshot) {
//     logger.warn("No data in user profile document.");
//     return null;
//   }
//
//   const userData = snapshot.data();
//   logger.info("User profile created in Firestore:", {
//     uid: event.params.userId,
//     displayName: userData.displayName,
//     role: userData.role,
//   });
//
//   // Future: Send welcome email, initialize user data, etc.
//   return null;
// });
