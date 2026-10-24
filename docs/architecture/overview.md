# SafeTalk System Architecture Overview

This page describes the high-level architecture of the SafeTalk application, separated between client and backend components.

---

## 1. High-Level Diagram

```
       ┌────────────────────────────────────────────────────────┐
       │                      FLUTTER CLIENT                    │
       │  ┌──────────────┐   ┌──────────────┐   ┌─────────────┐ │
       │  │  UI Screens  │◄──►│ Controllers  │◄──►│   Models    │ │
       │  └──────────────┘   └──────┬───────┘   └─────────────┘ │
       │                            │                           │
       │                            ▼                           │
       │                     ┌──────────────┐                   │
       │                     │   Services   │                   │
       │                     └──────┬───────┘                   │
       └────────────────────────────┼───────────────────────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            ▼                       ▼                       ▼
     ┌──────────────┐        ┌──────────────┐        ┌─────────────┐
     │Firebase Auth │        │  Firestore   │        │ Agora Voice │
     │Authentication│        │ Realtime DB  │        │   Calling   │
     └──────────────┘        └──────┬───────┘        └─────────────┘
                                    │
                                    ▼
                         ┌───────────────────────┐
                         │   Cloud Functions     │
                         │   & Payout Webhooks   │
                         └──────────┬────────────┘
                                    │
                                    ▼
                         ┌───────────────────────┐
                         │ Razorpay Payouts API  │
                         └───────────────────────┘
```

---

## 2. Client-Side Architecture (Flutter)

The Flutter application follows a clean separation of concerns:
*   **UI Screens ([app/lib/screens/](file:///d:/Coding/safe_talk/app/lib/screens/))**: Isolates Seeker pages ([user](file:///d:/Coding/safe_talk/app/lib/screens/user/)), Companion pages ([listener](file:///d:/Coding/safe_talk/app/lib/screens/listener/)), and shared screens (login, call screen, chat).
*   **Controllers ([app/lib/controllers/](file:///d:/Coding/safe_talk/app/lib/controllers/))**: State managers driving UI updates. For example, [SessionController](file:///d:/Coding/safe_talk/app/lib/controllers/session_controller.dart) connects Firestore events to screen actions.
*   **Models ([app/lib/models/](file:///d:/Coding/safe_talk/app/lib/models/))**: Structured schemas parsing Firestore documents into Dart objects.
*   **Services ([app/lib/services/](file:///d:/Coding/safe_talk/app/lib/services/))**: Independent wrapper modules for Auth, Firestore, WebRTC, Razorpay payments, and local cryptography.

---

## 3. Backend-Side Architecture (Firebase)

*   **Firebase Authentication**: Handles secure user registration, logins, and session persistence.
*   **Cloud Firestore**: Real-time Document Database that syncs profiles, active matched session records, chat rooms, and financial ledgers.
*   **Firebase Cloud Functions**: Runs background code on auth triggers, Firestore database triggers, pub/sub schedules, and HTTPS requests.

---

## 4. Platform Support & Device Scope (A7.6)

*   **Primary Tier — Mobile (Android & iOS)**:
    *   Target platforms for production release and end users.
    *   Features requiring native mobile hardware and SDKs: Agora RTC voice engine, Razorpay Checkout SDK, Google Play Services OAuth SSO, biometric authentication (`local_auth`), and FCM background notifications.
*   **Secondary Tier — Desktop & Web (Development & Testing)**:
    *   Supported for rapid development cycles, widget testing, and CI automated verification.
    *   Platform-restricted features (e.g., native Razorpay checkout, Agora native mobile bindings) gracefully degrade with fallback notices or mock stubs when executed on desktop environments.

---

### Navigation
**◄ [System Architecture Home](file:///d:/Coding/safe_talk/docs/system_architecture_specification.md)** | **[Table of Contents](file:///d:/Coding/safe_talk/docs/system_architecture_specification.md)** | **[Next: Matching Lifecycle](file:///d:/Coding/safe_talk/docs/architecture/matching_lifecycle.md) ──►**
