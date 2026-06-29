# SafeTalk Developer & Release Documentation

Welcome to the SafeTalk project documentation. This folder serves as the central directory for local setup, phase-wise development milestones, and release manuals for Google Play Store shipping.

## Document Index

1.  **[Phase-Wise Goals](file:///e:/Coding/safe_talk/docs/phase_wise_goals.md)**: A detailed roadmap broken down into development phases, enabling continuous progress over multiple sessions.
2.  **[User Intervention Manual](file:///e:/Coding/safe_talk/docs/user_intervention_manual.md)**: Step-by-step guides detailing where developer and client actions are required (Agora setup, Razorpay activation, App Store listing, and Google API credential generation).
3.  **[CI/CD Deployment Guide](file:///e:/Coding/safe_talk/docs/cicd_deployment_guide.md)**: A comprehensive guide mapping pipeline stages, required GitHub secrets, and Fastlane configurations for automated store shipping.
4.  **[Automated Test Suites Manual](file:///e:/Coding/safe_talk/docs/automated_test_suites.md)**: Full details on running test suites locally, mock coverage assertions, and test directory hierarchy mapping.
5.  **[System Architecture & Specifications Manual](file:///e:/Coding/safe_talk/docs/system_architecture_specification.md)**: The "Holy Book" containing the comprehensive system architecture, database schemas, cryptographic vault specifications, and transaction ledger details.



## Quick Local Environment Commands

To spin up the mock backend environment for local development:
```bash
# In the root workspace directory
firebase emulators:start
```
To run backend security rules and functions test suites:
```bash
cd firebase/functions
npm install
npm test
```
