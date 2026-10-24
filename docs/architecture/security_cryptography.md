# SafeTalk Security, Isolation, & Cryptography Protocols

This page outlines the cryptographic vault design, session chat encryption, Firestore security permissions, and signature verification logic used to isolate records.

---

## 1. Local Cryptography Vault ([VaultService](file:///d:/Coding/safe_talk/app/lib/services/vault_service.dart))

To protect users' sensitive emotional logs (Diaries), SafeTalk implements a client-side Zero-Knowledge Vault:

```
[User PIN Input] 
       │
       ├─► [Retrieve Salt base64 from vault_metadata.json]
       ▼
[PBKDF2 HMAC-SHA256 Derivation (50,000 Iterations)] 
       │
       ▼
[256-bit AES-GCM Key] 
       │
       ├─► Decrypt ciphertext payload in vault_notes.enc
       │
       └─► Verify GCM Authentication Tag (MAC) 
```

*   **Key Derivation**: The user sets a PIN. The service generates a random 256-bit salt, then derives a 256-bit key using **PBKDF2 with HMAC-SHA256** over 50,000 iterations.
*   **Encryption**: The diary data is serialized to JSON and encrypted using **AES-256-GCM**.
*   **Authentication**: The file payload saves the `ciphertext`, `nonce` (96-bit Initialization Vector), and the `mac` (GCM Authentication Tag). This protects the data against tampering.
*   **Zero-Knowledge**: The key exists only in-memory; it is never written to disk or sent to Firebase, ensuring maximum user privacy.

---

## 2. Session Chat Messaging Security ([ChatCryptoService](file:///d:/Coding/safe_talk/app/lib/services/chat_crypto_service.dart))

For real-time peer communication during active sessions, SafeTalk uses per-session symmetric authenticated encryption:

```
[Session Key Generated (256-bit Secure Random)]
       │
       ├─► Stored in session document protected by Firestore participant-only rules
       ▼
[AES-256-GCM Non-Deterministic Cipher]
       ├── Unique 96-bit IV per message
       ├── Ciphertext payload
       └── 128-bit Authentication MAC tag
```

*   **Confidentiality**: All chat messages exchanged in `/sessions/{sessionId}/messages` are encrypted with AES-256-GCM. Unauthenticated third parties or unauthorized users cannot read or tamper with the messages.
*   **Authenticity**: Each message bundle stores `{cipher, iv, mac}`. Tampered or corrupted payloads fail MAC verification gracefully.
*   **Security Scope**: Provides end-to-participant confidentiality against non-participants and network eavesdroppers. Note: Unlike the client-side Diary Vault which is zero-knowledge (derived purely from the user's secret PIN), the chat session key is coordinated across session participants.

---

## 3. Firestore Access Control Rules

Access control is locked down inside [firestore.rules](file:///d:/Coding/safe_talk/firestore.rules):
*   **`users`**: Allow reads on your own document or any document belonging to a `"listener"`. Allow writes only on your own document.
*   **`sessions`**: Allow read access only if the authenticated user's UID matches `seekerId` or `listenerId`. Status transitions are strictly gated:
    - `pending` can only be set upon initial creation by the seeker.
    - `payment_pending` can only be set by the matched listener.
    - `active` client writes are **denied**; activation is exclusively performed by the trusted `razorpayWebhook`.
    - Reviving `completed` sessions back to `active` is strictly blocked.
*   **`sessions/{sessionId}/messages`**: Check the parent session document via a `get()` rule to verify that the requester is an active participant in the session before allowing read/write operations on messages.
*   **`ledgers`**: Deny all write operations by clients. Only allow listeners to read their own ledger details.
*   **`notifications` & `mood_checkins`**: Strictly isolated to document owners (`request.auth.uid == userId`).

---

## 4. Webhook Signature Verification

The Razorpay webhook handler validates requests using `crypto` inside [index.js](file:///d:/Coding/safe_talk/firebase/functions/index.js):
1.  Extracts the `x-razorpay-signature` from request headers.
2.  Computes the HMAC-SHA256 digest of the raw request body using `RAZORPAY_KEY_SECRET`.
3.  Compares the digest against the header signature using timing-safe comparisons. If valid, updates session status to `"active"`.

---

### Navigation
**◄ [Previous: Database Schemas](file:///d:/Coding/safe_talk/docs/architecture/database_schema.md)** | **[Table of Contents](file:///d:/Coding/safe_talk/docs/system_architecture_specification.md)** | **[Next: Billing & Payouts](file:///d:/Coding/safe_talk/docs/architecture/billing_payouts.md) ──►**
