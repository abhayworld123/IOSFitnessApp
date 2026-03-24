# Step-by-Step: Firebase Auth (Google & Phone) Setup

Follow these steps in order to enable Google and Phone sign-in and wire the app.

---

## Step 1: Firebase Console – Enable Sign-In Methods

1. Open [Firebase Console](https://console.firebase.google.com/) and select your project (or create one).
2. In the left sidebar, go to **Build → Authentication**.
3. Open the **Sign-in method** tab.
4. **Enable Google**:
   - Click **Google** in the providers list.
   - Toggle **Enable** on.
   - Set **Project support email**.
   - Click **Save**.
5. **Enable Phone**:
   - Click **Phone** in the providers list.
   - Toggle **Enable** on.
   - Click **Save**.

---

## Step 2: Firebase Console – Add iOS OAuth Client (Google)

1. In Firebase Console, go to **Project settings** (gear icon next to “Project overview”).
2. Under **Your apps**, select your **iOS app** (bundle ID e.g. `com.qubefire.FitnessApp`).  
   - If you don’t have an iOS app, click **Add app** → **iOS**, enter the bundle ID, then register.
3. Download the latest **GoogleService-Info.plist** and replace the one in your Xcode project (e.g. drag into the FitnessApp target and ensure “Copy items if needed” is checked).
4. In the same **Project settings** page, scroll to **Your apps** and expand your iOS app.   
5. Under **Google Sign-In** (or in the SDK setup section), note the **iOS URL scheme** or **reversed client ID**.  
   - Alternatively, open **GoogleService-Info.plist** in a text editor and find the key **`CLIENT_ID`**.  
   - The value looks like: `123456789012-abcdefghijklmnop.apps.googleusercontent.com`.  
   - The **reversed client ID** is that value reversed: `com.googleusercontent.apps.123456789012-abcdefghijklmnop` (everything after `com.` stays in the same order; the numeric and suffix part become the “host” part before `.com`).

**Example:**

- `CLIENT_ID` = `123456789012-xyz.apps.googleusercontent.com`  
- Reversed client ID = `com.googleusercontent.apps.123456789012-xyz`

---

## Step 3: Add URL Scheme in Xcode (Reversed Client ID)

1. In Xcode, select the **FitnessApp** project in the navigator.
2. Select the **FitnessApp** target.
3. Open the **Info** tab.
4. Expand **URL Types** (or add one via **+** under URL Types).
5. Set:
   - **Identifier**: e.g. `Google Sign-In` (or your bundle ID).
   - **URL Schemes**: one entry, set to your **reversed client ID** (e.g. `com.googleusercontent.apps.123456789012-xyz`).  
     - This must match exactly the reversed client ID from `GoogleService-Info.plist` / Firebase.
6. **Role**: **Editor**.

**If you use the project’s Info.plist file directly:**

- Open **FitnessApp/Info.plist**.
- Find the `CFBundleURLTypes` → first item → `CFBundleURLSchemes` → first string.
- Replace `com.googleusercontent.apps.REPLACE_WITH_YOUR_REVERSED_CLIENT_ID` with your actual reversed client ID (from Step 2).

---

## Step 4: Resolve Packages and Build

1. In Xcode menu: **File → Packages → Resolve Package Versions** (or **Reset Package Caches** if needed).
2. Wait until **GoogleSignIn-iOS** (and other packages) finish resolving.
3. Build: **Product → Build** (or Cmd+B).
4. If you see errors in **AuthService.swift** related to Google Sign-In (e.g. `GIDSignInResult`, `idToken`, `signIn(withPresenting:)`):
   - Check the [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) README or API for the current method names and types.
   - Update the Google sign-in call in `AuthService.signInWithGoogle()` to match the current API (e.g. result type, token access).

---

## Step 5: Phone Auth – Simulator vs Real Device

**Simulator:**

- Phone sign-in uses the **reCAPTCHA** fallback.
- The app must have the **correct URL scheme** (Step 3) so Firebase can open the callback URL back into your app after reCAPTCHA.
- No extra Firebase/APNs setup required for simulator.

**Real device (recommended for production):**

1. In Firebase Console: **Project settings → Your apps → iOS app**.
2. Under **Apple app configuration**, upload your **APNs Authentication Key** (or APNs certificate):
   - **APNs Key**: .p8 file from Apple Developer, Key ID, Team ID, Bundle ID.
   - Or use **APNs certificate** (.p12).
3. Firebase uses this for **silent push** to verify the app; phone sign-in then often completes without showing reCAPTCHA.

---

## Step 6: Quick Checklist

- [ ] Firebase: **Google** and **Phone** sign-in methods enabled.
- [ ] **GoogleService-Info.plist** in the app and up to date.
- [ ] **Reversed client ID** derived from `CLIENT_ID` in that plist.
- [ ] **URL scheme** in Xcode (Info or Info.plist) set to that reversed client ID.
- [ ] **Packages resolved** and project **builds**.
- [ ] **AuthService** Google Sign-In API updated if the package API changed.
- [ ] (Optional) **APNs** configured in Firebase for phone auth on real devices.

---

## Troubleshooting

- **“No reversed client ID”**: Open `GoogleService-Info.plist` and look for `CLIENT_ID`; reverse it as in Step 2.
- **Google sign-in opens browser then nothing**: Confirm URL scheme matches reversed client ID exactly and `onOpenURL` in the app calls `GIDSignIn.sharedInstance.handle(url)`.
- **Phone “invalid phone number”**: Use E.164 format (e.g. `+1234567890`), including country code.
- **Phone verification hangs on simulator**: Ensure URL scheme is set so the reCAPTCHA callback can return to the app.
