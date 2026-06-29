# SafeTalk Database Schema & Index Specifications

This page outlines the Firestore collections, subcollections, document schemas, and required database indexes.

---

## 1. Document Schema Definitions

### Users Collection (`users/{uid}`)
Defines the profile and configurations of app participants.
```json
{
  "uid": "String (Auth UID)",
  "email": "String",
  "displayName": "String (Moniker/moniker)",
  "role": "String (user | listener | therapist)",
  "seekerData": {
    "walletBalance": "Double (Mock balance for local validations)",
    "preferredLanguages": ["en", "hi"],
    "safeCircle": ["UID_1", "UID_2"]
  },
  "listenerData": {
    "isOnline": "Boolean",
    "status": "String (online | busy | offline)",
    "languagesSpoken": ["en", "hi"],
    "specialties": ["Anxiety", "Grief", "Relationships"],
    "bio": "String",
    "stats": {
      "rating": "Double (e.g. 4.9)",
      "minutesListened": "Integer"
    }
  }
}
```

### Sessions Collection (`sessions/{sessionId}`)
Tracks the lifecycle of matching sessions.
```json
{
  "id": "String (Document ID)",
  "seekerId": "String (UID)",
  "seekerMoniker": "String",
  "seekerMoodTag": "String",
  "seekerConcern": "String",
  "listenerId": "String (UID | null)",
  "status": "String (pending | payment_pending | active | completed | cancelled | rejected)",
  "rejectedBy": ["UID_1", "UID_2"],
  "sessionType": "String (voiceCall | videoCall | messages)",
  "requestedAt": "Timestamp",
  "paymentId": "String (Razorpay Payment ID - set after validation)",
  "updatedAt": "Timestamp"
}
```

### Messages Subcollection (`sessions/{sessionId}/messages/{messageId}`)
Manages the real-time messages.
```json
{
  "text": "String (Encrypted ciphertext payload)",
  "senderId": "String (UID)",
  "timestamp": "ServerTimestamp"
}
```

### Ledgers Collection (`ledgers/{listenerId}`)
Financial transaction tracking.
```json
{
  "pendingPayout": "Double (Accumulated earnings awaiting settlement)",
  "totalEarned": "Double (Historical earnings paid out)",
  "lastPayoutAt": "Timestamp (ISO 8601 string)"
}
```

---

## 2. Required Firestore Indexes

To query companions based on language and online status efficiently, the following composite index is configured inside [firestore.indexes.json](file:///e:/Coding/safe_talk/firestore.indexes.json):
*   **Collection Group**: `users`
*   **Query Scope**: `COLLECTION`
*   **Indexed Fields**:
    1.  `role` (Ascending)
    2.  `listenerData.isOnline` (Ascending)
    3.  `listenerData.languagesSpoken` (Array Config: Contains)

---

### Navigation
**◄ [Previous: Matching Lifecycle](file:///e:/Coding/safe_talk/docs/architecture/matching_lifecycle.md)** | **[Table of Contents](file:///e:/Coding/safe_talk/docs/system_architecture_specification.md)** | **[Next: Security & Cryptography](file:///e:/Coding/safe_talk/docs/architecture/security_cryptography.md) ──►**
