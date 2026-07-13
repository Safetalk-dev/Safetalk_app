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
