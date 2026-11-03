# Paisa Vasool

**Pool. Optimize. Pay. Together.**

Paisa Vasool is an Android app prototype for organizing shared group expenses. Members can track a shared ledger, compare sample payment offers, and vote on proposed purchases. The project is built with Flutter and Firebase.

> **Project status:** This repository is a prototype, not a production wallet or payment service. Payments are simulated, offers are sample data, and the Firestore rules need a security review before use with real users or financial data. See [Security](SECURITY.md) and [Going live](#before-a-public-release).

## Screenshots

No genuine app screenshots are checked in yet. There was no Android device or emulator available when this README was updated, so screenshots have not been fabricated. See [`docs/screenshots/README.md`](docs/screenshots/README.md) for the agreed capture filenames and privacy checklist.

## What it does

- **Group ledger:** Create or join a group, set a spending limit, and track member contributions and group balances.
- **Payment requests:** Submit a purchase for group voting; approved requests can be recorded in the demo ledger.
- **Payment optimizer:** Compare the app's configured sample offer rules and estimate savings for a bill.
- **Discover:** Browse sample travel and food deals. These are illustrative and are not live merchant offers.
- **Savings:** View recorded savings and group spending summaries.
- **Ask PV:** Ask questions about a group's balance or payment options. It uses a local rules-based assistant by default; a configured Gemini API key enables remote AI responses.
- **Authentication:** Sign in with email/password or Google through Firebase Authentication. Apple sign-in is present in the code but requires platform and provider configuration.

## Technology

- Flutter / Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Analytics package
- Google Sign-In
- Optional Gemini API integration

## Requirements

- Flutter SDK with Dart 3.3 or later
- Android Studio and an Android SDK for Android builds
- A Firebase project for authentication and Firestore-backed app data

Check your local setup with:

```shell
flutter doctor
```

## Get started

1. Clone the repository and install its Dart dependencies:

   ```shell
   git clone https://github.com/Charis-E-Shiny/MoneySplit.git
   cd MoneySplit
   flutter pub get
   ```

2. Create a local environment file from the template:

   ```powershell
   Copy-Item .env.example .env
   ```

   On macOS or Linux, use `cp .env.example .env`.

3. Configure Firebase:
   - Create a Firebase project and register an Android app with application ID `com.paisavasool.paisa_vasool`.
   - Enable Email/Password and Google under **Authentication → Sign-in method**. For Google sign-in, register the Android signing certificate fingerprints in Firebase.
   - Create a Cloud Firestore database.
   - Set the required Firebase values in `.env` using the Firebase project settings and Android app configuration.
   - Review `firestore.rules` before publishing rules. The current rules are a prototype starting point, not a production security policy.

4. Configure optional integrations in `.env`:
   - `GOOGLE_WEB_CLIENT_ID` is used by Google sign-in.
   - `GEMINI_API_KEY` enables remote Gemini answers. Leave it empty to use the local assistant.
   - `PAYMENT_MODE` defaults to `demo`. Live payments are not implemented.

   The required Firebase values are listed in [`.env.example`](.env.example). The app reads `.env` as a bundled Flutter asset; fully restart or rebuild after changing it.

5. Run checks and launch on a connected Android device or emulator:

   ```shell
   flutter analyze
   flutter test
   flutter run
   ```

If a required Firebase value is missing, the app displays a setup screen. Never commit `.env` or put production secrets in a mobile app bundle.

## Build

To build an Android ARM64 APK for local testing:

```shell
flutter build apk --release --target-platform android-arm64
```

The output is `build/app/outputs/flutter-apk/app-release.apk`. **Do not distribute this artifact as a production release yet:** the checked-in Gradle configuration signs release builds with the debug key. Configure and protect a release keystore, verify the signing setup, and test the release build before publishing.

## Before a public release

This repository is not ready to handle real money or sensitive financial data. At minimum:

- **Payments:** `lib/services/payment_gateway.dart` simulates payments in demo mode and rejects live mode. A real integration needs a trusted backend to create orders and verify provider signatures. Do not treat Firestore ledger entries as proof of payment.
- **Security rules:** The current `firestore.rules` lets any signed-in user read group documents (to support invite lookup) and allows broad member writes. Redesign and test rules to enforce least privilege, validate all fields and transitions, and protect invite codes before onboarding real users.
- **Secrets:** `.env` is bundled into the application and can be extracted from an APK. Firebase client configuration is not an authorization boundary; secure access with Firebase rules and provider restrictions. Do not ship a Gemini key in the app; proxy AI requests through a secured backend.
- **Offers:** Optimizer rules and Discover deals are sample data, not guaranteed merchant discounts. Obtain and verify partner data before making claims to users.
- **Release:** Configure app signing, app-store metadata, crash/analytics settings, supported-device testing, and operational monitoring.
- **Privacy and compliance:** Review [`PRIVACY.md`](PRIVACY.md), complete its release checklist, and obtain appropriate legal and regulatory review for the markets in which the app will be offered.

## Project layout

```text
lib/
  data/          Sample Discover deals
  screens/       Authentication, groups, requests, savings, and other UI
  services/      Firebase access, authentication, payment hook, AI, optimizer
  env.dart       Environment/configuration access
  models.dart    Group, payment request, and transaction models
android/         Android application and Gradle configuration
test/            Dart and Flutter tests
docs/screenshots/ Screenshot capture guidance
firestore.rules  Prototype Firestore security rules
.env.example    Local configuration template
```

## Contributing

Bug reports, documentation fixes, and code contributions are welcome. Read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a change. Please do not include credentials, personal financial data, or screenshots containing real account information in issues or pull requests.

## Security

Please report suspected vulnerabilities privately rather than posting exploit details publicly. See [`SECURITY.md`](SECURITY.md) for reporting guidance.

## Privacy

See [`PRIVACY.md`](PRIVACY.md) for the current code-level data summary and the actions required before publishing a user-facing privacy notice.

## License

This project is licensed under the [MIT License](LICENSE).
