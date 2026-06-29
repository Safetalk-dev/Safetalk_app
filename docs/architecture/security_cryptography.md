# SafeTalk Security, Isolation, & Cryptography Protocols

This page outlines the cryptographic vault design, Firestore security permissions, and signature verification logic used to isolate records.

---

## 1. Local Cryptography Vault ([VaultService](file:///e:/Coding/safe_talk/app/lib/services/vault_service.dart))

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

## 2. Firestore Access Control Rules

Access control is locked down inside [firestore.rules](file:///e:/Coding/safe_talk/firestore.rules):
*   **`users`**: Allow reads on your own document or any document belonging to a `"listener"`. Allow writes only on your own document.
*   **`sessions`**: Allow read and write modifications only if the authenticated user's UID matches the session's `seekerId` or `listenerId`.
*   **`sessions/{sessionId}/messages`**: Check the parent session document via a `get()` rule to verify if the requester is a participant in the session before allowing read/write operations on messages.
*   **`ledgers`**: Deny all write operations by clients. Only allow listeners to read their own ledger details.

---

## 3. Webhook Signature Verification

The Razorpay webhook handler validates requests using `crypto` inside [index.js](file:///e:/Coding/safe_talk/firebase/functions/index.js#L261):
1.  Extracts the `x-razorpay-signature` from request headers.
2.  Computes the HMAC-SHA256 digest of the raw request body using `RAZORPAY_KEY_SECRET`.
3.  Compares the digest against the header signature. If valid, updates session status to `"active"`.

---

### Navigation
**◄ [Previous: Database Schemas](file:///e:/Coding/safe_talk/docs/architecture/database_schema.md)** | **[Table of Contents](file:///e:/Coding/safe_talk/docs/system_architecture_specification.md)** | **[Next: Billing & Payouts](file:///e:/Coding/safe_talk/docs/architecture/billing_payouts.md) ──►**
