# 🚀 START HERE - Cloud Sync Setup

## ✅ What's Already Done

- ✅ `cloud_sync_service.dart` - Fixed with correct Google Drive scopes
- ✅ `AndroidManifest.xml` - Configured with Google Play services
- ✅ All dependencies installed and working
- ✅ No syntax errors or compilation issues

---

## 📋 What You Need To Do

### Step 1: Get Your SHA-1 Fingerprint
Run this command:
```powershell
cd android
.\gradlew signingReport
```

**Look for output like this:**
```
Variant: debug
Config: debug
Store: C:\Users\YOUR_USERNAME\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE
SHA-256: ...
```

**Copy the SHA1 value** (you'll need this in Step 2)

---

### Step 2: Google Cloud Console Setup

1. Go to https://console.cloud.google.com/
2. Create a new project (or select existing)
3. Enable **Google Drive API**
4. Configure **OAuth consent screen** (External)
5. Create two OAuth credentials:
   - **Android OAuth client** (use your SHA-1 from Step 1)
   - **Web OAuth client**
6. **Copy the Web Client ID** (looks like: `123456789-abc.apps.googleusercontent.com`)

**Detailed instructions**: See [CLOUD_SYNC_SETUP.md](CLOUD_SYNC_SETUP.md)

---

### Step 3: Update build.gradle.kts

Edit: `android/app/build.gradle.kts`

Find the `defaultConfig` section and add this line:

```kotlin
defaultConfig {
    applicationId = "com.example.faustina"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    
    // ADD THIS LINE:
    manifestPlaceholders["googleSignInClientId"] = "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
}
```

Replace `YOUR_WEB_CLIENT_ID` with the actual Web Client ID from Step 2.

---

### Step 4: Test the App

```powershell
flutter clean
flutter pub get
flutter run
```

Navigate to **Cloud Sync** page and test:
1. Sign in with Google ✓
2. Sync data ✓
3. Restore data ✓

---

## 📚 Documentation Guide

- **START_HERE.md** ← You are here (quick start)
- **[CLOUD_SYNC_SETUP.md](CLOUD_SYNC_SETUP.md)** - Complete step-by-step setup (recommended)
- **[CONFIGURATION_TEMPLATE.md](CONFIGURATION_TEMPLATE.md)** - Quick config reference
- **[QUICK_COMMANDS.md](QUICK_COMMANDS.md)** - Useful commands
- **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - What was fixed

---

## ⚡ Quick Commands

### Get SHA-1:
```powershell
cd android
.\gradlew signingReport
```

### Run App:
```powershell
flutter clean
flutter pub get
flutter run
```

### Check for Issues:
```powershell
flutter doctor
flutter analyze
```

---

## ❓ Need Help?

**Most Common Issue**: `DEVELOPER_ERROR` when signing in
- **Cause**: SHA-1 fingerprint mismatch
- **Solution**: 
  1. Re-run `.\gradlew signingReport`
  2. Update SHA-1 in Google Cloud Console
  3. Wait 5-10 minutes
  4. Uninstall and reinstall app

**See full troubleshooting**: [CLOUD_SYNC_SETUP.md](CLOUD_SYNC_SETUP.md#troubleshooting)

---

## 🎯 Your Next Action

1. **Open terminal** and run: `cd android; .\gradlew signingReport`
2. **Copy the SHA-1** value
3. **Follow [CLOUD_SYNC_SETUP.md](CLOUD_SYNC_SETUP.md)** for Google Cloud Console setup

---

Good luck! 🚀
