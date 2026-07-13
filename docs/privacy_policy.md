# SafeTalk — Privacy Policy

**Effective Date:** July 14, 2026
**Last Updated:** July 14, 2026

SafeTalk ("we", "us", or "our") operates the SafeTalk mobile application (the "App"). This Privacy Policy explains how we collect, use, and protect your information when you use the App.

---

## 1. Information We Collect

### 1.1 Account Information
When you sign up, we collect your **email address** through Google Single Sign-On (SSO) for authentication purposes. No passwords are stored by SafeTalk.

### 1.2 Session Metadata
We collect minimal metadata about counseling sessions, including:
- Session timestamps (start and end time)
- Session mode (messaging, voice, or video)
- Payment transaction identifiers

### 1.3 Anonymous Identifiers
Seekers are assigned **temporary, randomized monikers** (e.g., "Mist Pebble #482"). Your real identity is never exposed to counselors or other users during sessions.

### 1.4 Payment Information
Payment processing is handled entirely by **Razorpay**, a PCI-DSS compliant third-party payment gateway. SafeTalk never stores, accesses, or processes your credit card numbers, UPI IDs, or banking details directly.

### 1.5 Counselor Case Notes
Counselors may maintain clinical case notes within the App. These notes are:
- Encrypted locally on the counselor's device using **AES-GCM-256** encryption
- Protected by a user-defined PIN via **PBKDF2 HMAC-SHA256** key derivation (50,000 iterations)
- **Never transmitted** to SafeTalk's servers in cleartext

---

## 2. How We Use Your Information

We use the collected information to:
- Authenticate your identity and manage your account
- Match seekers with available counselors
- Process session payments through Razorpay
- Send push notifications for incoming sessions and messages
- Maintain listener payout ledgers

We **do not** use your information for advertising, marketing profiling, or sale to third parties.

---

## 3. Data Encryption & Security

SafeTalk employs a **double-encryption vault architecture**:

- **Key Derivation**: PBKDF2 HMAC-SHA256 with 50,000 iterations and a 256-bit cryptographic salt
- **Encryption**: AES-GCM-256 with unique 96-bit nonces and 128-bit authentication tags
- **Zero-Trace Memory Management**: Decrypted data is held only in volatile RAM and is immediately wiped when the vault is locked

Session conversations are **not stored** permanently. Message data is deleted after the session ends.

---

## 4. Third-Party Services

SafeTalk integrates with the following third-party services:

| Service | Purpose | Privacy Policy |
|:--------|:--------|:---------------|
| **Firebase (Google)** | Authentication, database, cloud functions | [Firebase Privacy](https://firebase.google.com/support/privacy) |
| **Agora** | Real-time voice and video communication | [Agora Privacy](https://www.agora.io/en/privacy-policy/) |
| **Razorpay** | Payment processing | [Razorpay Privacy](https://razorpay.com/privacy/) |

---

## 5. Data Retention

- **Session messages**: Deleted upon session completion
- **Account data**: Retained while your account is active
- **Payment records**: Retained for 5 years as required by applicable financial regulations
- **Encrypted vault notes**: Stored locally on the counselor's device only; SafeTalk has no access

---

## 6. Your Rights

You have the right to:
- **Access** your account information at any time
- **Delete** your account and all associated data by contacting us
- **Request** a copy of the data we hold about you
- **Withdraw** consent for data processing at any time

---

## 7. Children's Privacy

SafeTalk is not intended for users under the age of 18. We do not knowingly collect personal information from minors. If we learn that we have collected information from a child under 18, we will delete it promptly.

---

## 8. Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be posted within the App and the "Last Updated" date will be revised. Continued use of the App after changes constitutes acceptance.

---

## 9. Contact Us

If you have questions about this Privacy Policy or your data, contact us at:

**Email:** privacy@safetalk.app
**Subject Line:** Privacy Policy Inquiry

---

*This policy is provided as a template. Consult with a legal professional to ensure compliance with applicable laws in your jurisdiction.*
