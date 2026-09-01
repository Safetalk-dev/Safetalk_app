# SafeTalk: Production Secret Binding & Signing Guide

This guide covers binding production API keys to Firebase Cloud Functions, generating the Android upload keystore, and configuring release signing.

---

## 1. Firebase Cloud Functions — Secret Binding

SafeTalk's cloud functions use `defineSecret()` to reference 4 secrets at runtime. These must be set via the Firebase CLI before deploying to production.

### Prerequisites
- Firebase CLI installed and logged in (`firebase login`)
- Project selected (`firebase use safe-talk-767df`)

### Set Secrets

Run each command and paste the corresponding key when prompted:

```bash
# Agora Video/Voice SDK credentials
firebase functions:secrets:set AGORA_APP_ID
firebase functions:secrets:set AGORA_APP_CERTIFICATE

# Razorpay Payment Gateway credentials
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
```

### Verify Secrets

```bash
# List all configured secrets
firebase functions:secrets:list

# Test access to a specific secret
firebase functions:secrets:access AGORA_APP_ID
```

### Deploy Functions to Production

```bash
firebase deploy --only functions
```

### Deploy Firestore Rules & Indexes

```bash
firebase deploy --only firestore
```

---

## 2. Android Upload Keystore Generation

Google Play requires all production app bundles to be signed with a consistent upload key.

### Generate Keystore

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You will be prompted for:
- **Keystore password**: Choose a strong password (save it securely)
- **Key password**: Can be the same as the keystore password
- **First and last name**: Your name or organization
- **Organization unit**: e.g., "SafeTalk Dev"
- **Organization**: e.g., "SafeTalk"
- **City/State/Country**: Your location

> **CRITICAL**: Store `upload-keystore.jks` securely. If lost, you cannot update your app on Google Play. Never commit it to git.

### Create `key.properties`

After generating the keystore, create `app/android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

> This file is gitignored and must be created manually on each development machine or injected via CI secrets.

### Register SHA-1 Fingerprints with Firebase (Required for Google Sign-In)

Generating and configuring the upload keystore above is not sufficient on its own for Google Sign-In to work. Google Play Services authenticates the *combination* of the app's package name (`com.safetalk.app`) and the SHA-1 fingerprint of the certificate that signed the running build. If that pair is not registered as an Android OAuth client on the Google Cloud project backing this Firebase project, sign-in fails on-device with `ApiException: 10` (`DEVELOPER_ERROR`) — no client-side code change can work around this; it is a console-side registration step.

> **Register all three fingerprints below.** Registering only one produces a deceptive symptom: sign-in works fine in local testing, then fails for every user who installs from Play.

1. **Debug keystore** — used by `flutter run` and local debug builds:

   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
   ```

2. **Upload keystore** — used for release builds and internal testing, generated above:

   ```bash
   keytool -list -v -alias upload -keystore app/android/app/upload-keystore.jks
   ```

3. **Play App Signing key** — obtained from **Play Console → Release → Setup → App signing**. Google re-signs your uploaded bundle with its own key before distributing it, so the SHA-1 that end users actually run under is *not* the upload key's — this fingerprint must be registered too, or production installs will fail even though your own test builds work.

For each fingerprint, copy the `SHA1:` value from the `keytool`/Play Console output and register it in **Firebase Console → Project settings → Your apps → Android app → Add fingerprint**.

**Verify registration took effect** by re-downloading `google-services.json` from Firebase Console and checking its `oauth_client` array:
- A registered Android fingerprint produces an entry with `"client_type": 1`.
- A config containing only a `"client_type": 3` (web) entry means no Android fingerprint is registered yet, and Google Sign-In will fail with Code 10.

---

## 3. GitHub Secrets Checklist

Configure these in **GitHub → Settings → Secrets and variables → Actions**:

| Secret Name | How to Get It |
|:---|:---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 upload-keystore.jks` (encode keystore) |
| `ANDROID_KEY_ALIAS` | `upload` (or whatever you chose) |
| `ANDROID_KEY_PASSWORD` | The key password from keytool |
| `ANDROID_STORE_PASSWORD` | The store password from keytool |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | GCP Console → IAM → Service Accounts → Create Key (JSON) |
| `PLAY_STORE_JSON_KEY` | Google Play Console → API Access → Service Account JSON |

---

## 4. Production Deployment Checklist

- [ ] All 4 Firebase secrets set (`AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`)
- [ ] Functions deployed to production
- [ ] Firestore rules and indexes deployed
- [ ] Upload keystore generated and stored securely
- [ ] `key.properties` created locally
- [ ] All 6 GitHub secrets configured
- [ ] Signed `.aab` builds and installs correctly
