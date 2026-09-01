# SafeTalk — Project State Specification

**Assessment date:** 2026-09-01
**Commit assessed:** `77aa377` + uncommitted working tree (26 files, +803 / −725)
**Scope:** Firebase backend completeness, Flutter app completeness, backend↔UI discrepancies and their semantic meaning.

This document describes **what the system actually is**, as opposed to what `docs/phase_wise_goals.md` claims it is. Companion document: [`future_actions.md`](./future_actions.md).

---

## 0. Executive Summary

| Dimension | Claimed (phase_wise_goals.md) | Actual |
|---|---|---|
| Phase 1 — Emulators & rules | ✅ complete | ~85% — rules exist and are tested; schema they enforce does not match what the client writes |
| Phase 2 — Live integrations | ✅ complete | ~45% — Agora voice is real; Razorpay, payouts, and video are simulated |
| Phase 3 — CI/CD | ✅ complete | ~30% — both workflows will fail on a clean runner |
| Phase 4 — Store launch | ✅ complete | ~40% — metadata scaffolded; the app cannot complete its own core loop |

**The single most important finding:** the end-to-end matching loop is broken in production. No listener is ever written to Firestore as `isOnline: true`, so `autoMatchSession` finds zero candidates for every request and immediately marks every session `rejected`. The app's headline feature cannot execute against the live backend. See D-01.

**Second most important:** message "encryption" derives its AES key from the session ID — a value stored in plaintext as the Firestore document ID — using a salt that exists only on the local device. Messages are neither confidential nor cross-device readable. See D-08.

**Google SSO:** the reported breakage was **not fixed**. What landed is an error-message improvement. See §4.

---

## 1. Firebase Backend Completeness

### 1.1 What exists

`firebase/functions/index.js` — 331 lines, 7 exported functions:

| Function | Type | Status |
|---|---|---|
| `onUserAuthCreated` | v1 auth `onCreate` | Live. Writes `users/{uid}` with `role: "user"`, `createdAt` (ISO string). |
| `autoMatchSession` | v2 `onDocumentWritten` on `sessions/{id}` | Live. Random pick among online listeners, excluding `rejectedBy`. Sends FCM to the chosen listener. |
| `autoTimeoutSessions` | v2 `onSchedule` every 1 min | Deployed but **inert** — reads fields the client never writes (D-04). |
| `generateAgoraToken` | v2 `onCall`, secrets `AGORA_APP_ID` / `AGORA_APP_CERTIFICATE` | Real `RtcTokenBuilder` token, with a silent mock-string fallback if secrets are missing. |
| `processPayout` | v2 `onCall`, secrets `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` | **Mock.** Logs a line and mutates the ledger. No RazorpayX HTTP call exists. |
| `onSessionCompleted` | v2 `onDocumentWritten` on `sessions/{id}` | Live, but duration maths always falls back to a flat 10 minutes (D-05). |
| `razorpayWebhook` | v2 `onRequest`, secret `RAZORPAY_KEY_SECRET` | Real HMAC-SHA256 signature verification against `req.rawBody`. Correct. |

### 1.2 Firestore

- **Rules** (`firestore.rules`, 60 lines) cover `users`, `sessions`, `sessions/{id}/messages`, `ledgers`. Unit-tested in `firebase/functions/__tests__/firestore.rules.test.js`.
- **Indexes** (`firestore.indexes.json`) — one composite index: `users` on `role` + `listenerData.isOnline` + `listenerData.languagesSpoken` (array-contains).
- **Emulators** configured for auth (9099), functions (5001), firestore (8080), UI on.

### 1.3 What is absent

- No **App Check** — every callable and the webhook are reachable by any client that has the (gitignored but shipped-in-APK) API key.
- No **custom claims** or admin role. `processPayout` is callable by any signed-in user for any `listenerUid` and any `amount` (D-11).
- No **Cloud Storage** rules or config, despite store metadata containing images.
- No collections for **notifications**, **safety reports**, **mood check-ins**, or **ledger transaction lines** — all four have UI surfaces in the app.
- **Two `onDocumentWritten` triggers registered on the same path** (`sessions/{sessionId}`). Every session write invokes both; `autoMatchSession`'s own `update()` re-invokes the pair. Bounded by early-return guards, but it doubles invocation cost on every write.
- No **secret values in Secret Manager** are verifiable from the repo. `defineSecret` deploys will block non-interactively if the secrets were never bound (`docs/secret_binding_guide.md` documents the intent, not a completed state).

### 1.4 Unused imports (dead surface)

`onDocumentCreated` and `getAuth` are imported in `index.js` and never used — residue from the removed `beforeUserCreated` blocking function (deleted in the uncommitted diff).

**Backend completeness: ~70% of the intended surface exists; ~40% of it actually functions end-to-end.**

---

## 2. Flutter App Completeness

**Size:** 47 Dart files, 16,280 LOC in `lib/` — of which 12,843 (79%) is screen code and 1,275 is service code. The UI is far ahead of the data layer.

### 2.1 Screen inventory by data source

**Wired to Firestore (8 of 24):**

| Screen | Source |
|---|---|
| `shared/auth_wrapper.dart` | `authStateChanges` + `UserService.getUser` |
| `shared/login_screen.dart` | `AuthService` |
| `shared/onboarding_screen.dart` | `UserService.createUser` — **unreachable in production** (D-02) |
| `shared/session_chat_screen.dart` | `sessions/{id}/messages` stream + `generateAgoraToken` |
| `user/user_layout.dart` | `UserService` + `MatcherService` (feeds `explore_screen`) |
| `listener/listener_layout.dart` | `SessionService.streamIncomingRequests` |
| `listener/dashboard_screen.dart` | `listenerData.stats` |
| `listener/profile_screen.dart` | `listenerData` |

**Local-state only (16 of 24)** — these render, animate, and persist nothing to the backend:

| Screen | Actual data source |
|---|---|
| `user/notification_screen.dart` | `_notifications = []` — literal empty list, no producer |
| `listener/notification_screen.dart` | `_notifications = []` — same |
| `listener/regulars_screen.dart` | `final seekers = []` — hardcoded empty |
| `user/regulars_screen.dart` | in-memory `_regularListenerNames`, never persisted |
| `user/messages_screen.dart` | `ChatController.userThreads` (local JSON file) |
| `listener/messages_screen.dart` | `ChatController.listenerThreads` (local JSON file) |
| `shared/history_screen.dart` | `ChatController` threads — never reads `sessions` |
| `listener/transactions_screen.dart` | `_transactions = []`; withdrawal amount hardcoded ₹4,250 |
| `shared/video_call_screen.dart` | 992 lines of pure mock — no Agora engine at all |
| `user/explore_screen.dart` | props from `user_layout` (Firestore-backed) — check-in score is local |
| remaining | presentational |

### 2.2 Platform coverage

`firebase_options.dart` defines **Android and Windows only**. iOS, macOS, Linux, and web all `throw UnsupportedError`. A `web/` directory and `windows/` runner are present; iOS is not configured at all despite the Play/App-Store framing.

### 2.3 Verified build health

```
flutter analyze  → 39 issues: 6 errors, 8 warnings, 25 info
flutter test     → 14/14 passed (4s)
```

- All 6 errors are in `integration_test/` — the `integration_test` dev-dependency is **commented out** in `pubspec.yaml:57-58`, so all three E2E suites fail to resolve `package:integration_test/integration_test.dart`. They have never run.
- The 14 passing unit tests run entirely against `fake_cloud_firestore`. **None of them exercise a Cloud Function, a security rule, or a real Firestore write.** They cannot detect any discrepancy in this document.

**App completeness: UI ~90%; data-layer wiring ~35%.**

---

## 3. Backend ↔ UI Discrepancies and Their Semantic Meaning

Ordered by severity. "Semantic meaning" = what the mismatch means about the system's intent versus its behaviour.

---

### D-01 — Listener online status is never written to Firestore *(Critical — breaks the core loop)*

- **Backend expects:** `autoMatchSession` queries `users where role == "listener" and listenerData.isOnline == true`.
- **UI does:** `listener_layout.dart:28` holds `bool _isOnline = true` as **local widget state**. `_toggleOnlineStatus` (`:70`) calls `setState` and nothing else. `onboarding_screen.dart:55` writes `isOnline: false` at account creation and it is never updated.
- **Semantic meaning:** the "Online & Available" toggle is a **rendering of intent, not a declaration of it**. The listener believes they are visible; the matcher cannot see them. Every seeker request therefore finds zero candidates and is written `status: "rejected"` within seconds. The product's entire value proposition — connecting a distressed person to a listener — cannot execute against the live backend. Every successful demo has run through `SessionController.isSimulated` (`accept_user_screen.dart:478`), which bypasses matching entirely.

---

### D-02 — Onboarding is dead code; role selection is unreachable *(Critical)*

- **Backend does:** `onUserAuthCreated` creates `users/{uid}` with `role: "user"` the instant an Auth account exists.
- **UI expects:** `auth_wrapper.dart:51` routes to `OnboardingScreen` **only when `getUser(uid)` returns null**.
- **Semantic meaning:** the two were written against different assumptions about who owns first-write of the user document. The function now always wins the race, so `getUser` returns a document, and the wrapper routes straight to `UserLayout`. **No user can ever choose "Be a Listener."** The listener side of a two-sided marketplace is unreachable through the product's own signup flow — listener accounts can only be created by direct console/DB manipulation. This compounds D-01: even the path that could set `isOnline` correctly is inaccessible.
- **Secondary effect:** if onboarding *were* reached, `UserService.createUser` uses `set()` without `merge`, which would erase the `fcmToken` and `createdAt` already written by the function and the FCM registration.

---

### D-03 — `sessionType` is written as a Dart enum `toString()` *(High)*

- **Schema says** (`docs/architecture/database_schema.md`): `"sessionType": "String (voiceCall | videoCall | messages)"`.
- **UI writes:** `session_controller.dart:134` — `sessionType: sessionType.toString()` → the literal string `"SessionType.voiceCall"`.
- **Backend reads it** into an FCM notification body: *"…is requesting a SessionType.voiceCall session."*
- **Semantic meaning:** an internal language-level representation leaked across the persistence boundary and out to the user-facing push notification. The documented schema is aspirational; the wire format is an implementation accident. `accept_user_screen.dart:198` has already hardcoded `'SessionType.messages'` as its fallback, meaning the accident has been **absorbed as a contract** by downstream code — cleaning it up now requires a data migration, not just a one-line fix.

---

### D-04 — Session timestamps: three components, three incompatible conventions *(High)*

| Component | Field | Type |
|---|---|---|
| `SessionModel.toJson` (client write) | `requestedAt` | Firestore `Timestamp` |
| `autoTimeoutSessions` (read) | `updatedAt` ?? `createdAt` | expects ISO-8601 string |
| `razorpayWebhook` / `onSessionCompleted` (write) | `updatedAt` | ISO-8601 string |
| `database_schema.md` (doc) | `updatedAt` | "Timestamp" |

- **What actually happens:** the client writes only `requestedAt`. `autoTimeoutSessions` therefore evaluates `new Date(undefined)` → `Invalid Date`, and `Invalid Date < tenMinutesAgo` is `false` for every session. **The 10-minute auto-timeout has never timed out a single session** and logs "No sessions to time out." once per minute, forever.
- **Semantic meaning:** a scheduled function running 43,200 times a month doing measurable billable work and zero useful work. Worse, it creates a **false sense of a safety net** — the "sessions cannot run past 10 minutes" guarantee that the UI promises the user ("Your 10-minute support session has safely concluded") is enforced only by a client-side `Timer`, which any client can ignore or lose.

---

### D-05 — Listener earnings are always a flat fallback *(High)*

- `onSessionCompleted` computes `minutes` from `after.createdAt` → absent (D-04) → `startedAt` is null → `minutes = 10` fallback → `earned = 50 INR` for **every session regardless of actual duration**.
- **Semantic meaning:** `billing_payouts.md` documents a per-minute tariff with an explicit formula. The deployed system implements a flat fee and *presents it as* a metered calculation. Any listener who works a 3-minute or 30-minute session is credited identically. This is a billing-integrity defect, not just a bug.

---

### D-06 — Three different, mutually inconsistent money models *(High)*

| Layer | Value |
|---|---|
| Seeker is charged | ₹150 / session (`session_controller.dart:105`) |
| Listener ledger is credited | ₹5/min × 10 min = ₹50 (`index.js`, `onSessionCompleted`) |
| Listener dashboard *displays* as earnings | `₹${_sessionsCount * 150}` (`dashboard_screen.dart:160`) |
| Withdrawal request sends | hardcoded `4250.0` (`transactions_screen.dart:145`) |

- **Semantic meaning:** the listener's dashboard tells them they earned 3× what the ledger actually credited, and the withdrawal button requests a fourth number unrelated to any of them. There is no single source of truth for money. The app never reads the `ledgers` collection at all — the collection the backend writes and the rules protect is **write-only in practice**. Shipping this creates a direct expectation-versus-payment dispute with every listener.

---

### D-07 — Payment is client-asserted; the webhook is decorative *(Critical — security)*

- **Intended flow** (`matching_lifecycle.md`): Razorpay → webhook verifies signature → sets `status: "active"`.
- **Actual flow:** `session_controller.dart:195` `paymentSucceeded()` calls `SessionService.markPaymentComplete()`, which writes `status: 'active'` **directly from the client**. Firestore rules permit any participant to update any field. On desktop/web the whole checkout is `_simulateRazorpaySuccess()`; on mobile the key is the placeholder `'rzp_test_demoKeySafeTalk'` (`razorpay_service.dart:62`), which is not a real Razorpay key.
- **Semantic meaning:** the webhook implements correct HMAC verification that **nothing depends on**. Payment enforcement is theatre: a seeker's client can move a session to `active` without any money moving, and the server has no rule preventing it. The signature-verification code exists to make the architecture document true, not to gate anything.

---

### D-08 — Message "encryption" uses a public identifier as the key material *(Critical — security/privacy)*

- `session_chat_screen.dart:117` — `_vaultService.encryptString(widget.sessionId, messageText)`.
- `VaultService.encryptString(pin, …)` runs PBKDF2 over the **`pin` argument** with the salt stored at the local `data/vault_metadata.json`.
- The "PIN" passed is the **session ID**, which is the Firestore document ID — stored in plaintext, visible to anyone with read access to the document.
- **Two independent failures:**
  1. **Confidentiality:** the key is derived from a value the ciphertext is stored next to. This is obfuscation, not encryption.
  2. **Function:** the salt is device-local. The listener's device has a *different* salt, so it derives a different key and **cannot decrypt the seeker's messages at all**. The UI renders `'Decrypt Error'` (`:801`) for every message from the other party. Cross-device chat has never worked.
  - Additionally, if the vault was never initialised, `encryptString` throws and `_sendMessage`'s catch block only calls `debugPrint` — **messages silently fail to send with no user feedback**.
- **Semantic meaning:** `security_cryptography.md` describes a genuine zero-knowledge design (PBKDF2-50k / AES-256-GCM) — and `VaultService` *does* implement it correctly for its intended use (local diary notes under a user-chosen PIN). The defect is that the chat feature **reuses the vault as a generic crypto utility with the wrong secret**. The primitive is sound; the key management is not. The app tells the user "your conversation is private and encrypted" (`chat_controller.dart:155`) while providing neither property.

---

### D-09 — Vault and notification settings write to a path that does not exist on mobile *(High)*

- `vault_service.dart:19` and `push_notification_service.dart:38` use the **relative** path `Directory('data')`, resolved against the process CWD.
- On Android/iOS the CWD is not a writable application directory. `OfflineChatService` does this correctly via `path_provider` (`:22`); the other two do not.
- **Semantic meaning:** two services were written and validated on Windows desktop and never re-validated on the actual target platform. On a real Android device the vault cannot initialise, so (via D-08) chat send fails silently, and the notification preference never persists. The desktop build has been the de-facto reference platform for a mobile product.

---

### D-10 — Firestore rules permit unrestricted field mutation → ledger can be minted *(Critical — security)*

- Rule: `allow update: if request.auth != null && (resource.data.seekerId == uid || resource.data.listenerId == uid)` — **no field-level constraints, no status-transition validation.**
- `onSessionCompleted` guards on `before.status !== "completed" && after.status === "completed"`. A participant can write `active` → `completed` → `active` → `completed` in a loop, crediting `pendingPayout` ₹50 each cycle.
- **Semantic meaning:** the rules encode *who* may write, and the functions assume the rules also encode *what* may be written. Neither layer validates state transitions, so the session state machine — which exists as an `enum SessionPhase` in the client and as prose in `matching_lifecycle.md` — **is not enforced anywhere on the server**. The financial ledger is directly reachable from an attacker-controlled state machine.

---

### D-11 — `processPayout` performs no authorization *(Critical — security)*

- The function checks only that a caller is authenticated, then accepts `listenerUid` and `amount` from the request body and increments `totalEarned`.
- The code comment concedes it: *"Only admins or automated triggers post-review should call this in production."*
- **Semantic meaning:** an acknowledged TODO shipped as a live production endpoint. Combined with D-10, the entire financial layer is writable by any signed-in user.

---

### D-12 — Language taxonomy is unspecified and already forked *(Medium)*

- `onboarding_screen.dart:19` hardcodes `['en']`, with **no UI to change it**.
- `firebase/functions/test/matching_e2e.js:21` seeds `languagesSpoken: ['English']`.
- `MatcherService` matches with `arrayContainsAny` — `'en'` and `'English'` never match.
- **Semantic meaning:** the composite index, the schema doc, and the matcher all assume a controlled vocabulary that was never defined. The project's own E2E test already uses a different one. Language-based matching is currently a no-op that appears to work because every seeker and every listener defaults to `'en'`.

---

### D-13 — Cloud matcher ignores language entirely, contradicting its own documentation *(Medium)*

- `matching_lifecycle.md`: *"queries available online listeners, **matching spoken languages**."*
- `autoMatchSession` queries `role` + `isOnline` only, then picks uniformly at random. No language filter, no rating, no load balancing, no specialty match.
- `MatcherService` (client, used only to populate the Explore list) *does* filter by language.
- **Semantic meaning:** two matching implementations exist with different logic — the client one decides what the seeker *sees*, the server one decides who they *get*. A seeker can browse a filtered, language-matched directory and then be assigned a random listener who shares no language with them. The composite index in `firestore.indexes.json` was built for a server-side query that was never written.

---

### D-14 — `safeCircle` stores display names, schema says UIDs, and writes never persist *(Medium)*

- Schema: `"safeCircle": ["UID_1", "UID_2"]`.
- `user_layout.dart:71` reads `safeCircle` into `_regularListenerNames`.
- `_toggleRegularStatus` (`:110`) mutates local state by **display name** and never writes to Firestore.
- **Semantic meaning:** the read path and write path disagree on identity semantics, and the write path does not exist. "Add to Safe Circle" is a purely visual affordance that resets on app restart — for a feature whose entire purpose is continuity of care with a trusted listener.

---

### D-15 — FCM delivers a notification with no way to act on it *(Medium)*

- `autoMatchSession` sends `data: { sessionId, sessionType }`.
- The client registers `onMessage` only (`push_notification_service.dart:96`). There is **no `onBackgroundMessage` handler, no `onMessageOpenedApp`, no `getInitialMessage`, and no Android notification channel**. `AndroidManifest.xml` declares `POST_NOTIFICATIONS` but no FCM service or default-channel metadata.
- **Semantic meaning:** the `sessionId` payload the backend carefully attaches is discarded on every device. Tapping the notification opens the app at whatever screen it was on. For a mental-health product where a listener must respond quickly to a distressed person, the notification is an alert with no action attached.

---

### D-16 — Empty-shell screens with no producer *(Medium)*

Both notification screens initialise to `[]`, `listener/regulars_screen` to `[]`, and `transactions_screen` to `[]`, with **no code path anywhere that appends to them**. There is no `notifications` collection in Firestore.

- **Semantic meaning:** these are not "not yet populated" — they are terminal. The UI was completed against a data model that was never built. `note.md` corroborates: `notifications`, `safe circle fetch`, `history`, `bill ledger`, and `emotional check-in log` are all still unticked, while the screens for all five are shipped and pixel-complete.

---

### D-17 — Session history is local-only *(Medium)*

`history_screen.dart` (1,314 lines) reads exclusively from `ChatController` threads, which come from local JSON files. It never queries `sessions`.

- **Semantic meaning:** the authoritative record of what happened lives on the server; the record the user is shown lives on the device. Reinstalling the app, or signing in on a second device, presents a user with an empty history despite a complete server-side session record. For a wellbeing product, continuity of one's own history is part of the therapeutic value.

---

### D-18 — Video sessions are offered and charged for but do not exist *(High)*

`explore_screen.dart` sells a "Video Call Session" at ₹150. `video_call_screen.dart` is 992 lines containing a hand-drawn mock peer feed (`// MOCK MAIN PEER VIEWPORT BACKGROUND`, `:609`) with **no `agora_rtc_engine` import**. Only `voice_call_screen.dart` initialises a real `RtcEngine`.

- **Semantic meaning:** a paid tier is fully represented in the purchase funnel and entirely absent from the delivery. `agora_rtc_engine` and the `CAMERA` permission are already dependencies, so the gap is implementation, not architecture — but as shipped this is charging for an undelivered service.

---

### D-19 — CI/CD cannot run *(High)*

| Problem | Location | Effect |
|---|---|---|
| `flutter format` was removed in Flutter 3.7+ | `flutter_ci.yml` "Verify formatting" | Step fails; command does not exist (`dart format`) |
| Pins `flutter-version: 3.22.x` (Dart 3.4) but `pubspec.yaml` requires `sdk: ^3.11.5` | `flutter_ci.yml` | `flutter pub get` fails on version solve |
| `google-services.json` and `firebase_options.dart` are **gitignored** | `.gitignore:16-17` | `flutter analyze` and `flutter build appbundle` both fail on a clean checkout — missing file and unresolved import |
| `integration_test` dev-dependency commented out | `pubspec.yaml:57` | 6 analyzer errors → `flutter analyze` step fails |
| `cache-dependency-path: firebase/functions/package-lock.json` — that file is gitignored | `firebase_ci.yml` | Cache setup and `npm ci` both fail (no lockfile in repo) |
| Node 20 in CI vs `engines.node: "22"` in `package.json` | both | Deploy-time engine mismatch |
| `key.properties` heredoc is indented; `EOF` terminator is indented | `flutter_ci.yml` | Properties file gets leading whitespace on every key; heredoc may not terminate |
| Functions use `defineSecret`; no evidence secrets are bound in Secret Manager | `firebase_ci.yml` deploy step | Non-interactive `firebase deploy` blocks awaiting secret values |

- **Semantic meaning:** the pipeline was authored as a specification of the intended process and marked complete without a green run. Phase 3's "Closed Testing Run — distribute the signed bundle to internal testers" cannot have happened through this pipeline. It is a document in YAML form.

---

### D-20 — Documentation asserts behaviour that the code does not implement *(Medium)*

| Doc claim | Reality |
|---|---|
| `billing_payouts.md` §3: *"The function calls the RazorpayX payouts endpoint using the verified API key and secret."* | `processPayout` only calls `logger.info`. No HTTP request exists. |
| `matching_lifecycle.md` §2: matcher matches spoken languages | It does not (D-13) |
| `security_cryptography.md` §1: *"the key exists only in-memory… ensuring maximum user privacy"* | True of the diary vault; false of chat, whose key is a public document ID (D-08) |
| `phase_wise_goals.md`: all 4 phases ✅ | See §0 |

- **Semantic meaning:** the docs describe the design intent and were checked off at design time rather than verification time. This is the most consequential discrepancy for *process*: it means the checklist can no longer be used to judge readiness, and any launch decision made from it will be made on false information. For a product carrying financial and mental-health obligations, "RazorpayX settlement is implemented" is a claim with regulatory weight.

---

### D-21 — Everything is uncommitted *(Low, process)*

26 modified files, +803/−725, sitting unstaged on top of `77aa377`. The last commit message announces Phase 4 release-signing completion; the actual state of the code is a working tree no one else can reproduce.

---

## 4. Google SSO — Status of the Reported Breakage

**Verdict: not fixed. The breakage was diagnosed correctly and then treated cosmetically.**

### What changed (uncommitted, in `app/lib/services/auth_service.dart`)

```dart
-  final GoogleSignIn _googleSignIn = GoogleSignIn();
+  final GoogleSignIn _googleSignIn = GoogleSignIn(
+    serverClientId: '124622276181-...apps.googleusercontent.com',
+  );
```
plus a null-credential guard, a `PlatformException` catch, and this new message:

> *"Google sign-in configuration error (Code 10). Please ensure SHA-1 fingerprint is registered in Firebase Console."*

### Why that does not fix it

`serverClientId` is **necessary** to receive an `idToken` (without it, `googleAuth.idToken` is null and `signInWithCredential` cannot authenticate) — so that part is a real prerequisite that was correctly added. But it is **not sufficient**. `ApiException: 10` / `DEVELOPER_ERROR` is raised by Google Play Services when the calling app's **package name + signing-certificate SHA-1** pair is not registered as an Android OAuth client on the Google Cloud project. That registration is console-side; no amount of Dart changes it.

The new catch block does not repair the flow — it **renames the failure**. The user still cannot sign in; they now see a more accurate error while not signing in.

### Evidence the SHA-1 was never registered

1. `app/android/app/google-services.json` contains exactly **one** `oauth_client` entry, with `client_type: 3` (web). There is **no `client_type: 1`** entry — that is the Android client, and it only appears once a SHA-1 is registered.
2. That file is dated **2025-06-11**. `upload-keystore.jks` was created **2025-07-14** — a month later. The release signing key's SHA-1 therefore cannot have been present when the config was generated.
3. `grep -rn "SHA-1|SHA1|keytool|fingerprint" docs/ .github/ app/android/` returns **only three hits**, all in `secret_binding_guide.md`, all about generating the keystore. **No document in the repository mentions registering a fingerprint with Firebase.** For a step that is mandatory for Google Sign-In on Android, that silence is conclusive about the process.

### Important caveat

`google-services.json` is gitignored and stale, and the Android plugin does not read `client_type: 1` at runtime (it passes `serverClientId` explicitly). So the local file is **strong evidence, not proof** — if a fingerprint was added in the console after 2025-06-11 without re-downloading the file, registration could exist. This is settled in one minute: re-download `google-services.json` from the Firebase Console and check for a `client_type: 1` entry, or open **Google Cloud Console → APIs & Services → Credentials** and look for an Android OAuth client for `com.safetalk.app`.

### Three fingerprints are required, not one

This is the part most likely to cause a second round of "it's still broken":

| Build | SHA-1 source | Registered? |
|---|---|---|
| Debug (`flutter run`) | `~/.android/debug.keystore` | No |
| Release / internal testing | `app/android/app/upload-keystore.jks` | No |
| Play Store install | **Play App Signing key** — Google re-signs the bundle | No |

Registering only the upload key produces the exact reported symptom: sign-in works in local testing, fails for every user who installs from Play.

### Two smaller SSO defects found alongside

- **User cancellation is reported as an error.** `signInWithGoogle` returns the string `'Google sign-in was cancelled.'` when `googleUser == null`, and `login_screen.dart:70` shows any non-null return in an error snackbar. Dismissing the account picker — a normal action — produces an error toast. Cancellation should return `null` and be distinguished from failure.
- **Raw exception text is surfaced to users.** The final catch now returns `'Google sign-in failed: ${e.toString()}'`, putting stack-trace-grade text in a snackbar. Acceptable while debugging, not for release.
- **Downstream:** even once SSO works, a Google sign-in lands on `UserLayout` with no chance to pick a role, per D-02.

---

## 5. What Actually Works

Worth stating plainly, because the defect list above is long and the foundation is not bad:

- Email/password auth, with genuinely thorough error mapping.
- Firestore security rules for read isolation — correct, and covered by real emulator-backed tests.
- `razorpayWebhook` HMAC-SHA256 verification against `rawBody` — textbook correct.
- `generateAgoraToken` — real `RtcTokenBuilder`, secrets via `defineSecret`.
- `VaultService` — PBKDF2-HMAC-SHA256 / 50k iterations / AES-256-GCM with authenticated nonce+MAC storage. Correct for its intended purpose; misapplied by the chat layer.
- `voice_call_screen.dart` — a real Agora RTC integration with permissions, mute, and lifecycle teardown.
- `OfflineChatService` — correct `path_provider` usage and Color↔int serialisation.
- Secret hygiene — `.env.local`, `*.jks`, `key.properties`, `google-services.json`, and `firebase_options.dart` are all untracked and gitignored. Verified: `git ls-files` returns nothing for any of them.
- The design system (`theme/tokens.dart`) and the UI craft across 12,843 lines are consistent and high quality.

---

## 6. Readiness Verdict

**Not shippable.** Blocking, in order:

1. The core loop cannot execute (D-01, D-02).
2. The financial layer is exploitable by any authenticated user (D-07, D-10, D-11) and internally inconsistent (D-06).
3. Chat is neither private nor cross-device functional (D-08, D-09), while telling users it is encrypted.
4. A paid tier is sold and not delivered (D-18).
5. Google SSO is broken on Android (§4).
6. CI cannot produce a verified build (D-19).

Sequenced remediation: [`future_actions.md`](./future_actions.md).
