# SafeTalk — Future Actions

**Created:** 2026-09-01
**Companion to:** [`project_state_spec.md`](./project_state_spec.md) — every `D-xx` reference points to a discrepancy documented there.

Actions are sequenced so that each wave unblocks the next. Within a wave, items are ordered by dependency. Effort estimates assume one developer familiar with the codebase.

---

## Wave 0 — Unblock verification (do first; nothing else is trustworthy until this is done)

Currently there is no way to observe whether a change worked, because every test that could catch a real defect either doesn't compile or runs against mocks.

### A0.1 — Restore the integration test suite `[S]`
Uncomment `integration_test` in `app/pubspec.yaml:57-58`. This clears all 6 analyzer errors and makes the three existing E2E suites runnable.
> Fixes the compile half of D-19. Note the suites themselves are largely stubbed (`auth_flow_test.dart` has its body commented out) — restoring them is step one, writing them is A0.3.

### A0.2 — Stand up an emulator-backed test loop `[M]`
Add a script that boots the emulator suite, seeds a listener and a seeker, and drives one full session request → match → accept → pay → chat → complete cycle, asserting on the resulting Firestore documents.
> **This is the highest-leverage item in the document.** D-01, D-02, D-04, D-05, D-12, and D-13 are all failures that a single honest end-to-end run would have surfaced immediately. `firebase/functions/test/matching_e2e.js` is a starting skeleton but seeds `languagesSpoken: ['English']` (D-12) and does not assert.

### A0.3 — Add regression tests for the specific defects below `[M]`
At minimum: listener goes online → appears in matcher results; session completes → ledger credited proportionally to duration; participant cannot write an arbitrary status; `processPayout` rejects a caller who is not the named listener.

### A0.4 — Decide the fate of `flutter analyze`'s 33 non-error findings `[S]`
8 warnings are dead code (`_hasActiveRequest`, `_isLoadingListeners`, two unused `sessionType` locals, unused imports in `matching_flow_test.dart`). The 4 `avoid_print` hits should become `debugPrint`. The 12 `use_build_context_synchronously` hits are latent crash sites worth a pass.

---

## Wave 1 — Make the core loop execute (P0)

The product currently cannot do the one thing it exists to do.

### A1.1 — Persist listener online status to Firestore `[S]` — **D-01**
`listener_layout.dart:70` `_toggleOnlineStatus` must write `users/{uid}.listenerData.isOnline` (and `.status`) alongside the `setState`. Initialise `_isOnline` from the stored value rather than hardcoding `true`, so the toggle reflects reality on launch.
> Also add an `onDisconnect`-equivalent: a listener who force-quits stays "online" forever and will be matched to seekers who then wait for nothing. Either a heartbeat field checked by the matcher, or set offline on app lifecycle detach.

### A1.2 — Resolve the onboarding race `[S]` — **D-02**
Pick one owner for first-write of the user document. Recommended: keep `onUserAuthCreated` (it survives client crashes) but have it write a **sentinel** — e.g. `profileComplete: false` and no `role` — and change `auth_wrapper.dart:51` to route to onboarding when `role` is absent or `profileComplete != true`, rather than when the document is null.
> Without this, listener accounts cannot be created through the product at all, so A1.1 is untestable via the real signup path.

### A1.3 — Change `createUser` to a merge write `[S]` — **D-02 secondary**
`user_service.dart:27` uses `set()` without `merge`, which erases the `fcmToken` and `createdAt` already on the document.

### A1.4 — Add role and language selection to onboarding `[M]` — **D-12**
`onboarding_screen.dart:19` hardcodes `['en']` with no UI. Add a language multi-select, and for listeners a bio and specialties input — `explore_screen` already renders all three and currently always falls back to placeholder copy.

### A1.5 — Define the language vocabulary `[S]` — **D-12**
Write the allowed codes down (ISO 639-1 recommended: `en`, `hi`, `ta`, …), put them in a shared constant, and fix `firebase/functions/test/matching_e2e.js:21` which currently seeds `'English'`.

### A1.6 — Normalise `sessionType` on the wire `[S]` — **D-03**
Write `sessionType.name` (`"voiceCall"`), not `sessionType.toString()`. Requires updating `accept_user_screen.dart:198` and `:504`, which have hardcoded the malformed form as their fallback. Add a backward-compatible read for existing documents, or migrate them — this string is currently visible in FCM notification bodies.

### A1.7 — Write `createdAt` and `updatedAt` consistently `[M]` — **D-04**
Decide one representation — recommend Firestore `Timestamp` / `FieldValue.serverTimestamp()` throughout, since it is server-authoritative and sortable — then:
- `SessionModel.toJson` writes `createdAt`;
- every `SessionService` mutator (`acceptSession`, `markPaymentComplete`, `endSession`, `cancelSession`, `rejectSession`) sets `updatedAt`;
- `autoTimeoutSessions` and `onSessionCompleted` read `Timestamp`, not `new Date(string)`;
- the webhook and `processPayout` stop writing ISO strings;
- update `database_schema.md`.
> Add a `startedAt`, set when status becomes `active`. Both the timeout and the billing calculation actually want session *start*, not document creation — the existing code comment already identifies this.

### A1.8 — Verify `autoTimeoutSessions` fires `[S]` — **D-04**
Once A1.7 lands, confirm a session actually times out. Then reconsider `every 1 minutes`: this is 43,200 invocations/month scanning a growing collection. `every 5 minutes` with a `where("status","==","active")` index, or a per-session scheduled task, is cheaper and sufficient for a 10-minute window.

---

## Wave 2 — Close the security and money holes (P0, ship-blocking)

Do not put this in front of real users or real money before this wave is complete.

### A2.1 — Authorize `processPayout` `[S]` — **D-11**
Require `request.auth.uid === listenerUid` (or an admin custom claim). Ignore the client-supplied `amount` entirely — read `pendingPayout` from the ledger server-side and pay that. As written, any signed-in user can credit any account any amount; the code comment already admits this.

### A2.2 — Constrain session writes in Firestore rules `[M]` — **D-10**
Add field-level and transition validation to the `sessions` update rule:
- only the seeker may create; only the assigned listener may move `pending → payment_pending`;
- `status: "active"` must not be client-writable at all (see A2.3);
- `seekerId`, `listenerId`, `createdAt` immutable after creation;
- reject `completed → active` so the ledger cannot be minted in a loop.
Extend `firestore.rules.test.js` to cover each transition — it currently tests read isolation only.

### A2.3 — Make payment server-authoritative `[M]` — **D-07**
Remove `markPaymentComplete` from the client. `status: "active"` should be set **only** by `razorpayWebhook` after signature verification, with the client observing the change through its existing session stream. The webhook logic is already correct; it just has nothing depending on it.

### A2.4 — Wire real Razorpay credentials `[S]` — **D-07**
`razorpay_service.dart:62` uses `'rzp_test_demoKeySafeTalk'`, which is not a real key. Load the key id from remote config or a build-time define — never hardcode. Until then, mobile checkout cannot succeed.

### A2.5 — Fix chat encryption key management `[L]` — **D-08**
This needs a design decision before any code. The current scheme (`encryptString(sessionId, …)`) cannot be patched — a key derived from the plaintext document ID is not a key, and a device-local salt makes cross-device decryption impossible in principle.

Three viable options, in increasing order of cost:
1. **Drop the E2E claim.** Rely on Firestore's transport and at-rest encryption plus the security rules, and change the UI copy that promises encryption (`chat_controller.dart:155`, `session_chat_screen.dart:1180`). Honest, cheap, and appropriate if the threat model is "other users", not "the operator".
2. **Per-session symmetric key**, generated by a Cloud Function at session start and delivered to both participants over the already-authenticated channel, stored in a subcollection the rules restrict to participants. Real confidentiality against other users; the operator can still decrypt.
3. **Proper E2E** with per-user keypairs (X25519), public keys in the user document, per-session key agreement. Correct, but a substantial project including key backup and multi-device recovery.

Whichever is chosen, the UI must stop claiming a property the system does not have. **Recommendation: option 2**, with copy that says "private to you and your listener" rather than "zero-knowledge".

### A2.6 — Surface send failures `[S]` — **D-08**
`session_chat_screen.dart:119` swallows encryption errors into `debugPrint`. A message that fails to send must show a failed state and a retry, not vanish.

### A2.7 — Fix `Directory('data')` on mobile `[S]` — **D-09**
`vault_service.dart:19` and `push_notification_service.dart:38` use a relative path that is not writable on Android/iOS. Use `path_provider` as `offline_chat_service.dart:22` already does. Until this lands, the vault cannot initialise on a real device, which cascades into D-08.

### A2.8 — Enable Firebase App Check `[M]`
Callables and the webhook are currently reachable by anything holding the API key that ships in the APK.

---

## Wave 3 — Make the money model coherent (P1)

### A3.1 — Pick one tariff and apply it everywhere `[M]` — **D-06**
Today: seeker pays ₹150, ledger credits ₹50, dashboard shows ₹150, withdrawal requests ₹4,250. Decide the actual economics (session price, platform take, listener rate), record it in `billing_payouts.md`, and derive **every** displayed number from the ledger.

### A3.2 — Read the ledger in the app `[M]` — **D-06**
`ledgers/{uid}` is written by functions and protected by rules but **never read by any client**. `transactions_screen.dart` should stream it for balance, and `dashboard_screen.dart:160` should stop computing earnings as `_sessionsCount * 150`.

### A3.3 — Remove the hardcoded withdrawal amount `[S]` — **D-06**
`transactions_screen.dart:145` sends `'amount': 4250.0` regardless of balance. Superseded by A2.1 (server reads the balance), but the client should stop sending a fabricated number.

### A3.4 — Bill on real duration `[S]` — **D-05**
Depends on A1.7's `startedAt`. Currently every session credits a flat ₹50 via the fallback branch, while the docs describe a per-minute formula.

### A3.5 — Add a ledger transaction log `[M]`
A `ledgers/{uid}/transactions/{id}` subcollection recording each credit and payout. `transactions_screen` renders a list that has no source (D-16), and financial operations need an audit trail independent of a running total.

### A3.6 — Implement the actual RazorpayX call `[L]` — **D-20**
`processPayout` only logs. `billing_payouts.md` §3 states it "calls the RazorpayX payouts endpoint" — that claim must either become true or come out of the doc. Needs idempotency keys, a payout status webhook, and failure/reversal handling.

---

## Wave 4 — Close the UI↔backend gaps (P1)

These are the screens that render perfectly and mean nothing.

### A4.1 — Build the notifications backend `[M]` — **D-16**
Both notification screens initialise to `[]` with no producer and there is no `notifications` collection. Either add one (written by `autoMatchSession`, session state changes, and payout events) or remove the screens. Shipping a permanently empty notification inbox is worse than not having one.

### A4.2 — Complete the FCM handling chain `[M]` — **D-15**
Add `onBackgroundMessage`, `getInitialMessage`, and `onMessageOpenedApp`; declare an Android notification channel in `AndroidManifest.xml`; deep-link the `sessionId` the backend already sends to the accept screen. Right now a listener gets an alert they cannot act on — which for this product is the difference between responding to someone in distress and not.

### A4.3 — Back session history with Firestore `[M]` — **D-17**
`history_screen.dart` (1,314 lines) reads only local `ChatController` threads. Query `sessions where seekerId|listenerId == uid, orderBy createdAt desc`. Requires a composite index. Until then, a reinstall or a second device shows an empty history.

### A4.4 — Persist Safe Circle `[S]` — **D-14**
`user_layout.dart:110` `_toggleRegularStatus` mutates local state only, keyed by display name while the schema specifies UIDs. Write to `seekerData.safeCircle` and standardise on UIDs (resolving to names at render). Also implement the listener-side counterpart — `listener/regulars_screen.dart:15` is a hardcoded empty list.

### A4.5 — Persist the mood check-in log `[M]`
`_moodScores` in `user_layout` is in-memory and lost on restart. `note.md` still lists "emotional check-in log" as outstanding. For a wellbeing product, the mood trend over time is arguably the most valuable data the app holds.

### A4.6 — Implement or withdraw video calling `[L]` — **D-18**
`explore_screen` sells a ₹150 video session; `video_call_screen.dart` is 992 lines of mock with no Agora import. `agora_rtc_engine` and the `CAMERA` permission are already in place, so the path is clear — but until it is built, **remove the video option from the purchase flow.** Charging for an undelivered service is the most exposed item in this document.

### A4.7 — Move matching logic server-side or align the two `[M]` — **D-13**
`MatcherService` (client) filters by language; `autoMatchSession` (server) picks uniformly at random from all online listeners. A seeker browses a language-matched directory and is assigned someone at random. Add language filtering (and ideally rating/load balancing) to the Cloud Function — the composite index for exactly this query already exists in `firestore.indexes.json` and is currently unused.

---

## Wave 5 — Fix Google SSO (P0 for launch; independent of the other waves)

See `project_state_spec.md` §4 for the full diagnosis. **The reported breakage was not fixed** — the uncommitted change added the required `serverClientId` and improved the error text, but the actual cause is console-side.

### A5.1 — Confirm the diagnosis `[S]` — 2 minutes
Google Cloud Console → APIs & Services → Credentials. Look for an **Android** OAuth client for package `com.safetalk.app`. The local `google-services.json` has only a `client_type: 3` (web) entry, which indicates none exists — but that file is stale (dated 2025-06-11) and gitignored, so confirm in the console rather than from the file.

### A5.2 — Register all three SHA-1 fingerprints `[S]` — **the actual fix**
Registering only one produces "works locally, fails for everyone on Play":

```bash
# 1. Debug key — for flutter run
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore -storepass android -keypass android

# 2. Upload key — for release builds and internal testing
keytool -list -v -alias upload \
  -keystore app/android/app/upload-keystore.jks
```

3. **Play App Signing key** — Play Console → Release → Setup → App signing. Google re-signs the bundle, so the SHA-1 users actually run is not the upload key's. Omitting this is the classic cause of "SSO works in testing, fails in production."

Add all three in Firebase Console → Project settings → Your apps → Android → Add fingerprint.

### A5.3 — Re-download `google-services.json` `[S]`
After registering, download the regenerated file and verify it now contains an `oauth_client` entry with `"client_type": 1`. That entry's presence is the confirmation the registration took.

### A5.4 — Test on a real device on all three build types `[S]`
Debug build, release build installed via ADB, and an internal-testing install from Play. All three must succeed. This cannot be validated on the Windows desktop build — `signInWithGoogle` returns "not supported on this platform" there, which is likely why the defect survived.

### A5.5 — Stop reporting cancellation as an error `[S]`
`auth_service.dart` returns `'Google sign-in was cancelled.'` when the user dismisses the picker, and `login_screen.dart:70` shows any non-null return as an error snackbar. Return `null` for cancellation, or a distinguishable sentinel, so a normal dismissal is silent.

### A5.6 — Remove raw exception text from user-facing strings `[S]`
`'Google sign-in failed: ${e.toString()}'` puts internal error detail in a snackbar. Log it; show the user something actionable.

### A5.7 — Document the fingerprint requirement `[S]`
Add a section to `docs/secret_binding_guide.md`. The guide already covers keystore generation and has **no mention of SHA-1 registration** — a mandatory step whose absence is exactly why this broke. Whoever sets up the next environment will hit the same wall.

---

## Wave 6 — Repair the release pipeline (P1)

Fixes for each item in D-19.

### A6.1 — `flutter format` → `dart format --set-exit-if-changed lib/` `[S]`
The `flutter format` subcommand was removed in Flutter 3.7+. This step fails today.

### A6.2 — Align the Flutter/Dart version `[S]`
CI pins `flutter-version: '3.22.x'` (Dart 3.4) while `pubspec.yaml` requires `sdk: ^3.11.5`. `flutter pub get` fails the version solve. Pin the version actually in use locally.

### A6.3 — Provide `google-services.json` and `firebase_options.dart` in CI `[M]`
Both are gitignored (correctly), so a clean checkout cannot analyze or build — `firebase_options.dart` is imported by `main.dart` and three integration tests. Inject them from base64 GitHub secrets in a setup step, the way the keystore already is.

### A6.4 — Commit the functions lockfile `[S]`
`firebase/functions/package-lock.json` is gitignored, but `firebase_ci.yml` sets `cache-dependency-path` to it and runs `npm ci` — which requires a lockfile. Both the cache step and the install fail. Lockfiles should be committed.

### A6.5 — Node 20 → 22 in CI `[S]`
`package.json` declares `engines.node: "22"`; the workflow installs 20.

### A6.6 — Fix the `key.properties` heredoc `[S]`
In `flutter_ci.yml`, the heredoc body is indented and the terminating `EOF` is indented without `<<-`. Every property gets leading whitespace, and termination is unreliable.

### A6.7 — Verify secrets are bound in Secret Manager `[S]`
The functions use `defineSecret` for four secrets. If they were never bound, `firebase deploy` blocks non-interactively waiting for values. Confirm with `firebase functions:secrets:access AGORA_APP_ID` before trusting the deploy step.

### A6.8 — Get one green run end to end `[S]`
Phase 3 and Phase 4 are marked complete in `phase_wise_goals.md`, including "Closed Testing Run — distribute the signed app bundle to a selected internal tester group." Given A6.1–A6.6, that cannot have happened through this pipeline. Until a run goes green, treat the pipeline as unverified.

---

## Wave 7 — Process and hygiene (P2)

### A7.1 — Correct the documentation `[M]` — **D-20**
Three specific claims are false and should be fixed at the source:
- `billing_payouts.md` §3 — RazorpayX endpoint is not called;
- `matching_lifecycle.md` §2 — the matcher does not filter by language;
- `security_cryptography.md` §1 — the zero-knowledge claim holds for the diary vault but not for chat.

### A7.2 — Re-baseline `phase_wise_goals.md` `[S]`
All four phases are ✅ against a system that cannot complete its core loop. Adopt a rule that a box is checked when a test or a verified run proves it, not when the code is written. This is the process fix that would have prevented most of this document.

### A7.3 — Commit the working tree `[S]` — **D-21**
26 modified files, +803/−725, unstaged. The last commit announces Phase 4 completion; the real state exists only on one machine.

### A7.4 — Remove simulation paths before release `[M]`
`SessionController.isSimulated`, `accept_user_screen.dart:462` "Simulate Incoming Match Request", `request_screen.dart:435` `_handleRazorpaySuccess('PAY-DEMOBYPASS-999')`, `_simulateRazorpaySuccess`, and `main.dart:172` "Demo Bypass" (which skips biometric lock entirely). Gate them behind `kDebugMode` or delete them. The biometric bypass in particular defeats the Safe Haven lock in a release build.

### A7.5 — Clean dead code `[S]`
Unused `onDocumentCreated` and `getAuth` imports in `index.js`; the no-op `_onSessionChanged` in `listener_layout.dart:64`; the 8 analyzer warnings.

### A7.6 — Decide the platform story `[S]`
`firebase_options.dart` supports Android and Windows only; iOS/macOS/Linux/web throw `UnsupportedError`. A `web/` directory and a Windows runner are present and partially maintained (there are desktop-specific fallbacks throughout the services — and those fallbacks are why D-09's mobile path bug survived). Either commit to Android-only for launch and stop carrying desktop branches, or configure the other platforms properly.

---

## Suggested sequencing

| Wave | Theme | Gate |
|---|---|---|
| **0** | Test infrastructure | Nothing below is verifiable without it |
| **1** | Core loop | Ship-blocking — the product does not work |
| **2** | Security & payments | Ship-blocking — money and privacy are exposed |
| **5** | Google SSO | Ship-blocking, fully parallel — can start today |
| **3** | Money model coherence | Before any listener is paid |
| **6** | CI/CD | Before any external distribution |
| **4** | UI↔backend gaps | Before public launch; A4.6 is urgent (paid tier undelivered) |
| **7** | Docs & hygiene | Continuous |

**Start with:** A0.1 (one line, clears 6 errors), A5.1–A5.2 (SSO, console-side, ~15 minutes, independent of everything), A1.1 and A1.2 (two small changes that together restore the core loop).

Effort key: `[S]` under a day · `[M]` 1–3 days · `[L]` a week or more.
