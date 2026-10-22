# SafeTalk Billing & Automated Payout Ledger Systems

This document describes the financial architecture, billing tariff, and ledger audit mechanisms governing SafeTalk sessions and listener payouts (A3.1 - D-06).

---

## 1. Rate Tariff & Economics Specification

SafeTalk operates on a transparent, single-source-of-truth financial model:

*   **Seeker Session Charge**: **₹150.00 INR** flat fee per session (up to 10 minutes), captured server-authoritatively via Razorpay standard checkout and verified via webhook HMAC signatures.
*   **Listener Remuneration Rate**: **₹5.00 INR** per minute metered against verified call/chat session duration.
*   **Minimum Duration**: 1 minute.
*   **Standard Ceiling**: 10 minutes (maximum earned: ₹50.00 INR per standard session; hard capped at 15 minutes for grace periods).
*   **Platform Take / Infrastructure Margin**: **₹100.00 INR** retained for Agora RTC media servers, Firebase infrastructure, SMS/FCM delivery, and gateway processing fees.
*   **Calculation Formula**:
    $$\text{Earned Amount} = \min(15, \max(1, \text{Elapsed Minutes})) \times ₹5.00$$

---

## 2. Server-Authoritative Ledger Flow

```
[Session ended status: "completed"]
               │
               ▼
[Trigger: onSessionCompleted Function]
               │ Calculates duration (completedAt - startedAt)
               ▼
[Atomic Transaction in Firestore: /ledgers/{listenerUid}]
               ├── Increment pendingPayout by earned amount
               └── Append credit entry to /ledgers/{listenerUid}/transactions/{txId}
```

1.  **Session Completion**: When a session moves to status `"completed"`, the `onSessionCompleted` trigger calculates the verified session duration using Firestore server timestamps (`completedAt - startedAt`).
2.  **Atomic Firestore Ledger Updates**: The function increments the listener's ledger details dynamically in Firestore:
    ```javascript
    await db.collection("ledgers").doc(listenerUid).set({
      pendingPayout: FieldValue.increment(earned),
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });
    ```
3.  **Transaction Audit Log**: A credit record is written to `/ledgers/{listenerUid}/transactions/{txId}`:
    ```javascript
    await txRef.set({
      type: "credit",
      amount: earned,
      sessionId: sessionId,
      durationMinutes: minutes,
      ratePerMinute: 5.0,
      timestamp: FieldValue.serverTimestamp(),
      description: `Peer Session (${minutes} mins)`
    });
    ```
    *This runs fully isolated on the server side; security rules forbid client-side write access to ledgers and transactions.*

---

## 3. Payout Settlement & Bank Transfer

1.  **Payout Request**: When the listener requests a settlement via the [TransactionsScreen](file:///d:/Coding/safe_talk/app/lib/screens/listener/transactions_screen.dart) or Profile screen, it triggers the HTTPS callable function `processPayout`.
2.  **Authorization**: The function enforces `request.auth.uid === listenerUid` or admin privileges. Client-supplied amounts are ignored.
3.  **Transaction Settlement**: Within a Firestore transaction:
    *   `pendingPayout` is read directly from `/ledgers/{listenerUid}`. If $\le 0$, the request is safely rejected.
    *   `pendingPayout` is reset to `0.0`.
    *   `totalEarned` is incremented by the settled amount.
    *   `lastPayoutAt` is updated with `FieldValue.serverTimestamp()`.
    *   An audit record is appended to `/ledgers/{listenerUid}/payouts/{payoutId}` and `/ledgers/{listenerUid}/transactions/{txId}` (type `"debit"`).
4.  **RazorpayX API Integration**: In production environments with active RazorpayX corporate credentials, the function dispatches the transfer to the RazorpayX Payouts API using the payout ID as the idempotency key. In sandbox/staging environments, the payout is simulated with full internal ledger consistency.

---

### Navigation
**◄ [Previous: Security & Cryptography](file:///d:/Coding/safe_talk/docs/architecture/security_cryptography.md)** | **[Table of Contents](file:///d:/Coding/safe_talk/docs/system_architecture_specification.md)** | Next: None
