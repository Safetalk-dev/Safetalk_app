# SafeTalk Billing & Automated Payout Ledger Systems

This page describes the financial ledger updates and RazorpayX payout calculations.

---

## 1. Rate Tariff Configuration

*   **Tariff Rate**: **₹5.00 INR** per minute.
*   **Minimum Duration**: 1 minute.
*   **Calculation Formula**:
    $$\text{Earned Amount} = \text{Duration (minutes)} \times \text{Rate Per Minute}$$

---

## 2. Ledger Update Flow

```
[Session ended status: completed]
               │
               ▼
[Trigger: onSessionCompleted Function]
               │ Calculate duration (endedAt - startedAt)
               ▼
[Atomic Increment in Firestore /ledgers/{listenerUid}]
```

1.  **Session Completion**: When a session moves to status `"completed"`, the `onSessionCompleted` trigger calculates the session duration (using differences between `createdAt` and `updatedAt`).
2.  **Atomic Firestore updates**: It increments the listener's ledger details dynamically in Firestore using:
    ```javascript
    await db.collection("ledgers").doc(listenerUid).set({
      pendingPayout: FieldValue.increment(earned)
    }, { merge: true });
    ```
    *This runs fully isolated on the server side, preventing clients from modifying balances directly.*

---

## 3. RazorpayX Bank Settlement

1.  **Payout Request**: When the companion requests a settlement via the [TransactionsScreen](file:///e:/Coding/safe_talk/app/lib/screens/listener/transactions_screen.dart), it triggers the HTTPS callable function `processPayout`.
2.  **API Execution**: The function calls the RazorpayX payouts endpoint using the verified API key and secret.
3.  **Ledger Clearing**: On success, the function clears `pendingPayout` and increases `totalEarned` in the Firestore ledger document:
    ```javascript
    await ledgerRef.set({
      pendingPayout: 0.0,
      totalEarned: FieldValue.increment(amount),
      lastPayoutAt: new Date().toISOString()
    }, { merge: true });
    ```

---

### Navigation
**◄ [Previous: Security & Cryptography](file:///e:/Coding/safe_talk/docs/architecture/security_cryptography.md)** | **[Table of Contents](file:///e:/Coding/safe_talk/docs/system_architecture_specification.md)** | Next: None
