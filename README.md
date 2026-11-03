# Paisa Vasool: Pool. Optimize. Pay. Together.

Flutter app (Android) for group wallets, built to match your FlutterFlow design:
onboarding, login/sign-up (email + **Google**), home dashboard, group wallet,
Discover deals, **Payment Optimizer**, group **approval voting**, payment receipt with
auto-split, Group Savings charts, and the **Ask PV** AI assistant.

Backend: **Firebase Auth + Cloud Firestore**. AI: **Gemini** (optional; works offline without a key).

> **Status:** Firebase Auth, Firestore, and Analytics use the FlutterFire packages declared in
> `pubspec.yaml`; Firebase configuration is read from `.env`. The Android platform folder still
> needs to be generated once with `flutter create` before the app can be built. Payments are
> in **demo mode** (see the end).

---

## Prerequisites

1. Flutter SDK (3.24 or newer): https://docs.flutter.dev/get-started/install
2. Android Studio (for the Android SDK) and VS Code with the **Flutter** extension
3. Run `flutter doctor` and fix anything it flags
4. A Google account for Firebase (free "Spark" plan is enough)

## Step 0: Generate the Android project

Install Flutter 3.24 or newer and the Android SDK, open this folder in VS Code, then run:

```bash
flutter create --org com.paisavasool --project-name paisa_vasool --platforms android .
flutter pub get
```

This keeps the existing `lib/` code and adds the `android/` folder. Your app id is
`com.paisavasool.paisa_vasool`. This Flutter app uses FlutterFire packages, so add Firebase
dependencies with `flutter pub add`/`pubspec.yaml`; do not add the native Firebase BoM or
`firebase-analytics` Gradle dependency from a native Android guide. FlutterFire manages those
Android SDK dependencies.

Then make two edits:

**a)** `android/app/src/main/AndroidManifest.xml`: add this line just above `<application`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
and change `android:label="paisa_vasool"` to `android:label="Paisa Vasool"`.

**b)** `android/app/build.gradle.kts` (or `build.gradle`): make sure `minSdk` is **23 or higher**:

```kotlin
minSdk = 23
```

## Step 1: Create the Firebase project

1. https://console.firebase.google.com > **Add project**.
2. **Add app > Android.** Package name: `com.paisavasool.paisa_vasool`.
   For **SHA-1**, run this and paste the SHA1 line it prints:
   - Mac/Linux: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Windows: `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android`

   (Release APKs from `flutter build apk` are signed with this same debug key by default. If you
   later use your own keystore, add its SHA-1 too.)
   The provided `google-services.json` is for this Android app id. The Flutter app initializes
   Firebase using the matching values in `.env`.
3. **Build > Authentication > Get started > Sign-in method**: enable **Email/Password** and **Google**
   (pick a support email). Optional: Apple needs an Apple Developer account.
4. **Build > Firestore Database > Create database** (production mode, nearest region, e.g. `asia-south1`).
5. Firestore **Rules** tab: paste the contents of `firestore.rules` from this folder and **Publish**.

## Step 2: Add your API keys

Open **`.env`** in the project root. This is the one place for all keys:

| Key | Where to find it |
|---|---|
| `FIREBASE_API_KEY` | Firebase console > gear icon > Project settings > General > **Web API Key** |
| `FIREBASE_APP_ID` | Same page > Your apps > Android app > **App ID** (looks like `1:123:android:abc`) |
| `FIREBASE_MESSAGING_SENDER_ID` | Same page > **Project number** |
| `FIREBASE_PROJECT_ID` | Same page > **Project ID** |
| `FIREBASE_STORAGE_BUCKET` | Optional |
| `GOOGLE_WEB_CLIENT_ID` | Authentication > Sign-in method > Google > Web SDK configuration > **Web client ID** |
| `GEMINI_API_KEY` | https://aistudio.google.com/apikey (optional, enables real AI answers) |
| `GEMINI_MODEL` | Optional, defaults to `gemini-2.0-flash`; change if Google retires it |
| `PAYMENT_MODE` | `demo` (default) |
| `RAZORPAY_KEY_ID` | Reserved for when you add a real gateway |

Save the file and **fully restart** the app (hot reload does not re-read `.env`).
If a required key is still a placeholder, the app shows an "Add your API keys" screen listing what is missing.
The Firebase sender ID and storage bucket in this workspace's `.env` were filled from
`google-services.json`; confirm the remaining values belong to the Firebase project you intend to use.

## Step 3: Run it on your Samsung A56

1. On the phone: Settings > About phone > Software information > tap **Build number** 7 times,
   then Settings > Developer options > turn on **USB debugging**.
2. Connect by USB, accept the prompt, check with `flutter devices`.
3. `flutter run`

## Step 4: Build the APK

```bash
flutter build apk --release --target-platform android-arm64
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Copy it to the phone (USB, Drive, WhatsApp to self),
tap it, and allow "Install unknown apps" when asked. The A56 is 64-bit ARM, so the `android-arm64` build is
smaller and works.

## How it works

- **Sign in:** email/password and Google via Firebase Auth. Apple uses Firebase's OAuth flow (needs Apple setup).
- **Groups:** create one (you become Admin) or join with the 6-character invite code shown in group settings.
- **Pool:** "Add Money" records your contribution. Balance = contributed - spent.
- **Pay / Discover:** pick a deal or enter a bill. The **optimizer** (`lib/services/optimizer.dart`) compares
  gift card, credit card and UPI offers and ranks them by effective cost.
- **Approval:** a request goes to the group. **Majority approval** unlocks it; the admin then taps **Pay now**.
- **Receipt:** transaction id, original vs paid amount, and an equal split across members. Savings feed the
  **Group Savings** screen (monthly trend and category breakdown).
- **Ask PV:** uses Gemini with your group's numbers as context. With no key it still answers offline for
  "cheapest way to pay ₹X", savings, and balance questions.

## Where to edit things

```
.env                          all API keys
lib/services/optimizer.dart   offer rules (percent, cap, minimum, category)
lib/data/deals.dart           sample deals on the Discover tab
lib/services/payment_gateway.dart   payment hook
firestore.rules               database security rules
lib/theme.dart                colors and fonts
```

## Going live (read before real money or real users)

- **Payments are simulated.** "Pay now" moves numbers in your Firestore ledger, not real money. A real shared
  wallet that holds users' money is regulated in India (RBI payment aggregator / PPI rules). Practical routes:
  use a licensed partner (Razorpay, Cashfree, PhonePe PG) or keep the pool as a ledger and have the admin pay
  from their own account. For a gateway: create orders on your own server, open the checkout from the app,
  verify the signature server-side, then mark the request paid. Implement it in `payment_gateway.dart`
  and set `PAYMENT_MODE=live`.
- **Offers and deals are sample data.** Real discounts need a partner/offer API or your own agreements.
  Do not advertise offers you cannot actually honour.
- **Keys in `.env` ship inside the APK** and can be extracted. Firebase keys are designed for that (security comes
  from Firestore rules; restrict the API key to your app in Google Cloud Console). The **Gemini key is different**:
  for a public release, call Gemini from a Cloud Function and keep the key on the server.
- Firestore rules in this repo are a sensible starting point; review them before launch (group names and invite
  codes are readable by any signed-in user so that joining works).

## Troubleshooting

- **Google sign-in fails / `ApiException: 10`**: package name or SHA-1 in Firebase does not match the app, or
  `GOOGLE_WEB_CLIENT_ID` is missing/wrong. Fix, wait a few minutes, rebuild.
- **`Permission denied` from Firestore**: publish `firestore.rules` and make sure you are signed in.
- **Build fails with minSdk error**: set `minSdk = 23` (Step 0b).
- **No internet in the release APK only**: the INTERNET permission is missing (Step 0a).
- **`.env` not found**: keep it in the project root and listed under `assets:` in `pubspec.yaml` (already done).
