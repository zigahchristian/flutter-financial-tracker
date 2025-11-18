# Configuration Template

## 1. Android Build Configuration

### File: `android/app/build.gradle.kts`

After you obtain your OAuth Client ID from Google Cloud Console, add it to your `build.gradle.kts` file.

Find the `defaultConfig` section and add the `manifestPlaceholders` line:

```kotlin
defaultConfig {
    applicationId = "com.example.faustina"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    
    // Add this line with your actual Client ID
    manifestPlaceholders["googleSignInClientId"] = "YOUR_CLIENT_ID.apps.googleusercontent.com"
}
```

**Important:** Replace `YOUR_CLIENT_ID` with your actual Web Client ID from Google Cloud Console.

---

## 2. Get Your OAuth Client ID

Follow these steps from the `CLOUD_SYNC_SETUP.md` guide:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Find your **Web client** OAuth 2.0 Client ID
4. Copy the entire Client ID (it looks like: `123456789-abc123def456.apps.googleusercontent.com`)
5. Paste it into the `build.gradle.kts` file

---

## 3. Get SHA-1 Fingerprint

Run this command to get your debug SHA-1:

```powershell
cd C:\sandbox\faustina\android
.\gradlew signingReport
```

Or use keytool:

```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy the SHA-1 fingerprint and add it when creating the Android OAuth client in Google Cloud Console.

---

## 4. Complete Setup Checklist

- [ ] Created Google Cloud project
- [ ] Enabled Google Drive API
- [ ] Configured OAuth consent screen
- [ ] Created Android OAuth client with SHA-1
- [ ] Created Web OAuth client
- [ ] Updated `build.gradle.kts` with Web Client ID
- [ ] AndroidManifest.xml has Google Play services metadata (already done ✓)
- [ ] Tested sign-in functionality

---

## 5. Testing

After configuration:

```powershell
flutter clean
flutter pub get
flutter run
```

Navigate to Cloud Sync page and test:
1. Sign in with Google
2. Sync data
3. Restore data

---

## Need Help?

Refer to `CLOUD_SYNC_SETUP.md` for detailed step-by-step instructions.
