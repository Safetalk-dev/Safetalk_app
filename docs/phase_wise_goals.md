# Phase-Wise Goals: SafeTalk Development Roadmap

This document outlines the phase-wise development milestones to build, test, and ship SafeTalk over multiple sessions. Each phase contains distinct, actionable items.

---

## Phase 1: Local Backend & Emulator Setup (Days 1–4)
*   **Goal**: Establish a fully verified, sandbox development environment where the Flutter client communicates seamlessly with local Firebase Emulators.
*   **Tasks**:
    *   [x] Initialize Local Firebase Emulators (Auth, Firestore, Cloud Functions).
    *   [x] Configure Firestore Security Rules inside [firestore.rules](file:///e:/Coding/safe_talk/firestore.rules) to cover the `messages` and `ledgers` collections.
    *   [x] Add index declarations inside [firestore.indexes.json](file:///e:/Coding/safe_talk/firestore.indexes.json) to support listener language queries.
    *   [x] Inject conditional emulator initialization code inside [main.dart](file:///e:/Coding/safe_talk/app/lib/main.dart).
    *   [x] Configure local function keys inside `firebase/functions/.env.local` using dummy tokens.
    *   [x] Execute rules and triggers unit tests using Jest:
        ```bash
        cd firebase/functions && npm test
        ```

---

## Phase 2: Live Feature Integrations (Days 5–7)
*   **Goal**: Move the application from simulated mocks to live API integrations.
*   **Tasks**:
    *   [x] **Agora RTC Integration**: Connect [VoiceCallScreen](file:///e:/Coding/safe_talk/app/lib/screens/shared/voice_call_screen.dart) to the token generation backend.
    *   [x] **Razorpay Standard Checkout**: Wire [RazorpayService](file:///e:/Coding/safe_talk/app/lib/services/razorpay_service.dart) to client checkout screens.
    *   [x] **Webhook Handling**: Setup a Firestore listener/webhook receiver function to handle successful checkouts robustly.
    *   [x] **Firebase Cloud Messaging (FCM)**: Configure push notifications for new message notifications and incoming voice call invitations.

---

## Phase 3: CI/CD & Play Store Deployment Pipeline (Days 8–10)
*   **Goal**: Setup automated workflows to build, sign, test, and upload the application continuously.
*   **Tasks**:
    *   [x] **Flutter GitHub Actions Workflow**: Configure builds for linting, testing, and compile outputs (`.aab` and `.apk`).
    *   [x] **Firebase GitHub Actions Workflow**: Setup automatic security rules and functions deployment on pushes to `main`.
    *   [x] **Fastlane Setup**: Link Fastlane with the Google Play Developer API using Service Account JSON credentials.
    *   [x] **Closed Testing Run**: Distribute the signed app bundle to a selected internal tester group.

---

## Phase 4: Listing Compliance & Launch Submission (Days 11–14)
*   **Goal**: Satisfy store verification policies, deploy the backend to production, and submit for Google review.
*   **Tasks**:
    *   [ ] **Secret Configuration**: Bind production secret keys to live Firebase Cloud Functions (Agora ID, Agora Certificate, Razorpay Keys) using GCP Secret Manager.
    *   [ ] **Google Play Listing Assets**: Upload final app icons, promotional banners, policy documents, and screenshots.
    *   [ ] **Store Submission**: Submit the finalized bundle for production review and publication.
