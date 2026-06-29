# SafeTalk CI/CD Deployment Guide

This document details the architecture, configuration, and workflows of the SafeTalk automated CI/CD deployment pipeline. The pipeline ensures that both the Flutter client and the Firebase backend are continuously validated, built, and deployed on updates.

---

## 1. Pipeline Architecture

SafeTalk utilizes **GitHub Actions** for orchestration and **Fastlane** for target Android App Store releases.

```
                  [Developer pushes to main branch]
                                 │
                                 ▼
                     ┌───────────────────────┐
                     │ GitHub Actions Runner │
                     └───────────┬───────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
     ┌───────────────────────┐       ┌───────────────────────┐
     │  Flutter CI Workflow  │       │  Firebase CI Workflow │
     └───────────┬───────────┘       └───────────┬───────────┘
                 │                               │
                 ├─► Linting / Formatting        ├─► Install npm pkgs
                 ├─► Flutter Analyzer            ├─► Jest Test Execution
                 ├─► Unit & Widget Tests         ├─► Emulator Rule Tests
                 │                               │
                 ▼ (Signed Build)                ▼ (Pushed to Cloud)
     ┌───────────────────────┐       ┌───────────────────────┐
     │  Fastlane Deployment  │       │ Firebase Deploy CLI   │
     └───────────┬───────────┘       └───────────────────────┘
                 │
                 ├─► Link Google API JSON
                 ├─► Upload to Alpha Track
                 ▼
     ┌───────────────────────┐
     │ Google Play Console   │
     └───────────────────────┘
```

---

## 2. GitHub Secrets Configuration

To execute builds and deployments, you must configure the following Secrets under **Settings -> Secrets and variables -> Actions** in your GitHub repository:

| Secret Name | Type | Description |
| :--- | :--- | :--- |
| `ANDROID_KEYSTORE_BASE64` | Text | Base64-encoded string of your `upload-keystore.jks` file. |
| `ANDROID_KEY_ALIAS` | Plaintext | The key alias specified during keystore generation (e.g., `upload`). |
| `ANDROID_KEY_PASSWORD` | Plaintext | The password for the specific key inside the keystore. |
| `ANDROID_STORE_PASSWORD` | Plaintext | The master password for the keystore file. |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | JSON | The GCP service account JSON key with Firebase Admin access permissions. |
| `PLAY_STORE_JSON_KEY` | JSON | The Google Cloud service account JSON key linked to the Google Play Developer Console. |

---

## 3. Workflows Configuration

### A. Flutter CI/CD Pipeline
File Path: [.github/workflows/flutter_ci.yml](file:///e:/Coding/safe_talk/.github/workflows/flutter_ci.yml)
*   **Trigger**: Fires on any push or pull request to the `main` branch.
*   **Key Operations**:
    1.  Validates formatting via `flutter format`.
    2.  Checks static code constraints using `flutter analyze`.
    3.  Runs unit and widget tests: `flutter test`.
    4.  Extracts and decodes the keystore from `ANDROID_KEYSTORE_BASE64`.
    5.  Compiles the production Android App Bundle: `flutter build appbundle --release`.
    6.  Uploads the `.aab` binary output as a downloadable build artifact.

### B. Firebase CI/CD Pipeline
File Path: [.github/workflows/firebase_ci.yml](file:///e:/Coding/safe_talk/.github/workflows/firebase_ci.yml)
*   **Trigger**: Fires on any push or pull request touching the `firebase/`, `firestore.rules`, or `firestore.indexes.json` directories.
*   **Key Operations**:
    1.  Installs NodeJS dependencies.
    2.  Spins up the Firebase Emulator local sandbox environment inside the runner.
    3.  Executes Firestore Security Rules and Cloud Functions unit/integration tests.
    4.  Pushes update changes to the live Firebase instance using the CLI credentials if merged to `main`.

---

## 4. Troubleshooting Releases

### 1. Fastlane App Bundle Upload Rejections
*   **Error**: `Google Api Error: Invalid request - Only releases with a status of draft may be created on this track.`
*   **Solution**: Ensure that you don't have an unsubmitted active release draft in the Google Play Console for the track you are targeting. Delete the draft in the Console or change the Fastlane lane configuration to commit the release directly.

### 2. Gradle Keystore Build Failures
*   **Error**: `Keystore file .../upload-keystore.jks not found for signing config.`
*   **Solution**: Check that the `ANDROID_KEYSTORE_BASE64` secret in GitHub is formatted as a single line without whitespace or line-break wraps. Ensure that your `key.properties` file points to the correct relative paths.
