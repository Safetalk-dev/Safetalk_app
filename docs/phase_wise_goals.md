# Phase-Wise Goals: SafeTalk Development Roadmap

This document outlines the phase-wise development milestones and current verification baseline for SafeTalk. Items are marked completed only when verified by automated tests or live deployment.

---

## Phase 1: Local Backend & Emulator Setup (Verified)
*   **Goal**: Establish a fully verified development environment where the Flutter client communicates seamlessly with Firebase Emulators and local test suites.
*   **Tasks & Verification**:
    *   [x] **Firebase Emulators Configuration**: Auth, Firestore, and Cloud Functions emulators configured in `firebase.json`.
    *   [x] **Firestore Security Rules**: Rules in [firestore.rules](file:///d:/Coding/safe_talk/firestore.rules) covering `users`, `sessions`, `messages`, `ledgers`, `transactions`, `notifications`, and `mood_checkins`. Verified via automated rules tests.
    *   [x] **Index Declarations**: Composite indexes declared in [firestore.indexes.json](file:///d:/Coding/safe_talk/firestore.indexes.json) for listener queries, session histories, and ledger audits.
    *   [x] **Conditional Emulator Wiring**: Emulator connection logic wired into [main.dart](file:///d:/Coding/safe_talk/app/lib/main.dart).
    *   [x] **Local Secrets & Env**: Functions secrets defined with fallback support.

---

## Phase 2: Core Loop & Live API Integrations (Verified)
*   **Goal**: Transition from simulated mocks to live, server-authoritative API integrations and cryptographically sound mechanisms.
*   **Tasks & Verification**:
    *   [x] **Autonomous Matching & Role Router**: Implemented server-side language filtering in `autoMatchSession` with dynamic ISO language matching. Verified via [matching_flow_test.dart](file:///d:/Coding/safe_talk/app/test/matching_flow_test.dart).
    *   [x] **Server-Authoritative Payment**: Razorpay HMAC signature verification via `razorpayWebhook`; status activation restricted to webhook; client revival and client activation denied by security rules. Verified via [regression_test.dart](file:///d:/Coding/safe_talk/app/test/regression_test.dart).
    *   [x] **Agora RTC Voice Integration**: [VoiceCallScreen](file:///d:/Coding/safe_talk/app/lib/screens/shared/voice_call_screen.dart) connected to `generateAgoraToken` Cloud Function.
    *   [x] **Messaging & Diary Cryptography**: Zero-knowledge PBKDF2/AES-GCM for Diary Vault; per-session AES-256-GCM with authenticated MACs for chat messages. Verified via [chat_crypto_service_test.dart](file:///d:/Coding/safe_talk/app/test/services/chat_crypto_service_test.dart) and [vault_service_test.dart](file:///d:/Coding/safe_talk/app/test/services/vault_service_test.dart).
    *   [x] **Full Ledger Financial Model**: Real duration calculation (`completedAt - startedAt`), ₹5/min rate, atomic balance increments, transaction audit trail, and client ledger streaming in [TransactionsScreen](file:///d:/Coding/safe_talk/app/lib/screens/listener/transactions_screen.dart). Verified via [ledger_service_test.dart](file:///d:/Coding/safe_talk/app/test/services/ledger_service_test.dart).
    *   [x] **FCM Push Notification Handling**: Background handler entry-point, Android high-importance channel, initial message click, and session deep-linking.
    *   [x] **Google SSO Error Handling**: Silent cancellation, Code 10 diagnostic scripts, and server client ID override. Verified via [auth_service_test.dart](file:///d:/Coding/safe_talk/app/test/services/auth_service_test.dart).

---

## Phase 3: CI/CD & Play Store Deployment Pipeline (Repaired & Staged)
*   **Goal**: Automated GitHub Actions workflows to build, sign, test, and package the application continuously.
*   **Tasks & Verification**:
    *   [x] **Flutter CI/CD Workflow**: [flutter_ci.yml](file:///d:/Coding/safe_talk/.github/workflows/flutter_ci.yml) repaired (aligned Dart SDK ^3.11.5, `dart format`, `flutter analyze` with 0 issues, 44 unit tests passing, base64 secret decoding, clean heredocs, and release `.aab` compilation).
    *   [x] **Firebase CI/CD Workflow**: [firebase_ci.yml](file:///d:/Coding/safe_talk/.github/workflows/firebase_ci.yml) updated to Node 22, Java 21, and locked npm dependencies.
    *   [x] **Fastlane Android Setup**: Metadata and lanes scaffolded under `app/android/fastlane/`.
    *   [ ] **Closed Testing Run**: Distribute signed bundle to closed internal testing track on Google Play Console (awaiting repository secret population).

---

## Phase 4: Listing Compliance & Launch Submission (Pending Secrets & Review)
*   **Goal**: Satisfy store verification policies, bind production secrets in GCP Secret Manager, and submit for Google review.
*   **Tasks & Status**:
    *   [x] **Secret Configuration Guide**: Comprehensive binding guide in [secret_binding_guide.md](file:///d:/Coding/safe_talk/docs/secret_binding_guide.md) for Agora credentials, Razorpay keys, and SHA-1 keystore fingerprints.
    *   [x] **Gating of Simulation Paths**: Biometric bypass, demo payment bypass, and simulate buttons safely gated behind `kDebugMode` for release builds.
    *   [ ] **Production Secret Deployment**: Run `firebase functions:secrets:set` on live project with production API keys.
    *   [ ] **Google Play Console Release**: Upload release bundle `app-release.aab` and complete store review submission.
