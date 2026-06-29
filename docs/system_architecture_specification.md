# SafeTalk: System Architecture & Specifications Manual
## Project Table of Contents

This manual is divided into sub-pages to facilitate navigation across different sections of the SafeTalk system architecture and implementations.

---

### Page Index

1.  **[1. Architecture Overview](file:///e:/Coding/safe_talk/docs/architecture/overview.md)**
    *   System architecture block diagram.
    *   Client separation of concerns (Screens, Controllers, Models, Services).
    *   Backend services components (Auth, Firestore, Functions).
2.  **[2. Seeker-Listener Matching Lifecycle](file:///e:/Coding/safe_talk/docs/architecture/matching_lifecycle.md)**
    *   Step-by-step match-making sequence diagram.
    *   Matching logic and state transitions list.
    *   Standard checkout validation flow.
3.  **[3. Database Schemas & Indexes](file:///e:/Coding/safe_talk/docs/architecture/database_schema.md)**
    *   Document structure mapping for `users`, `sessions`, `messages`, and `ledgers` collections.
    *   Firestore composite index settings for languages spoke query.
4.  **[4. Security & Cryptography Protocols](file:///e:/Coding/safe_talk/docs/architecture/security_cryptography.md)**
    *   Client-side Zero-Knowledge Encryption key derivation and GCM authentication tag.
    *   Firestore security rules permissions.
    *   Webhook signature verification checks.
5.  **[5. Billing & Automated Payout Ledger Systems](file:///e:/Coding/safe_talk/docs/architecture/billing_payouts.md)**
    *   Tariff calculations and duration formulas.
    *   Firestore atomic increment triggers on session completion.
    *   Settlement processing via RazorpayX.
