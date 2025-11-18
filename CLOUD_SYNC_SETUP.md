# Cloud Sync Setup Guide

## Overview
This guide will help you configure Google Sign-In and Google Drive sync for the Faustina app.

---

## Prerequisites
- Flutter project with `google_sign_in` package installed
- Google account for development
- Access to [Google Cloud Console](https://console.cloud.google.com/)

---

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **Select a Project** → **New Project**
3. Enter project name (e.g., "Faustina Finance Tracker")
4. Click **Create**

---

## Step 2: Enable Required APIs

1. In your Google Cloud project, go to **APIs & Services** → **Library**
2. Search for and enable:
   - **Google Drive API**
   - **Google Sign-In API** (or People API)

---

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** (or Internal if you have a Google Workspace)
3. Click **Create**

### Fill in the required fields:
- **App name**: Faustina Finance Tracker
- **User support email**: Your email
- **App logo**: (optional)
- **App domain**: (optional for testing)
- **Authorized domains**: (leave empty for testing)
- **Developer contact**: Your email

4. Click **Save and Continue**

### Scopes:
1. Click **Add or Remove Scopes**
2. Add the following scopes:
   - `.../auth/userinfo.email`
   - `.../auth/userinfo.profile`
   - `.../auth/drive.appdata`
   - `.../auth/drive.file`
3. Click **Update** → **Save and Continue**

### Test Users (if External):
1. Click **Add Users**
2. Add your Google account email
3. Click **Save and Continue**

4. Review summary and click **Back to Dashboard**

---

## Step 4: Create OAuth 2.0 Credentials

### For Android:

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Select **Android** as application type
4. Fill in:
   - **Name**: Faustina Android
   - **Package name**: `com.example.faustina` (from your build.gradle.kts)
   - **SHA-1 certificate fingerprint**: (see below)

#### Getting SHA-1 Fingerprint:

**For Debug Build:**
```powershell
cd C:\sandbox\faustina\android
.\gradlew signingReport
```

Look for the **SHA1** under `Variant: debug`. It will look like:
```
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE
```

**Alternative method (using keytool):**
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

5. Copy the SHA-1 and paste it into the Google Cloud Console
6. Click **Create**
7. **Save the Client ID** (you'll need this)

### For Web (Optional, for testing):

1. Click **Create Credentials** → **OAuth client ID**
2. Select **Web application**
3. Fill in:
   - **Name**: Faustina Web
   - **Authorized redirect URIs**: `http://localhost` (for testing)
4. Click **Create**
5. **Save the Client ID**

---

## Step 5: Configure Android Project

### Update `android/app/build.gradle.kts`:

Add the following to the `defaultConfig` section:

```kotlin
defaultConfig {
    applicationId = "com.example.faustina"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    
    // Add this line
    manifestPlaceholders["googleSignInClientId"] = "YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com"
}
```

Replace `YOUR_WEB_CLIENT_ID_HERE` with your actual Web Client ID from Step 4.

---

## Step 6: Update AndroidManifest.xml

The file is located at: `android/app/src/main/AndroidManifest.xml`

Add the following **inside** the `<application>` tag:

```xml
<application>
    <!-- ... existing code ... -->
    
    <!-- Google Sign-In Configuration -->
    <meta-data
        android:name="com.google.android.gms.version"
        android:value="@integer/google_play_services_version" />
</application>
```

Also ensure you have internet permission (should already be there):

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- ... rest of manifest ... -->
</manifest>
```

---

## Step 7: Test the Setup

1. Run the app:
```powershell
flutter run
```

2. Navigate to **Cloud Sync** page
3. Click **Sign in with Google**
4. You should see the Google Sign-In dialog
5. Select your account and grant permissions

---

## Troubleshooting

### Error: "DEVELOPER_ERROR" or "API_NOT_CONNECTED"
- **Cause**: SHA-1 fingerprint mismatch or OAuth client not configured correctly
- **Solution**: 
  1. Regenerate SHA-1 using `gradlew signingReport`
  2. Update the SHA-1 in Google Cloud Console
  3. Wait 5-10 minutes for changes to propagate
  4. Uninstall and reinstall the app

### Error: "SIGN_IN_FAILED"
- **Cause**: OAuth consent screen not configured or APIs not enabled
- **Solution**:
  1. Verify Google Drive API is enabled
  2. Check OAuth consent screen is configured
  3. Add your test account to test users (if External)

### Error: "NETWORK_ERROR"
- **Cause**: No internet connection or firewall blocking
- **Solution**: Check internet connection and try again

### Error: "SCOPE_DENIED"
- **Cause**: User denied required permissions
- **Solution**: Sign in again and accept all permissions

### SHA-1 Not Showing in `signingReport`
Run this command in the android directory:
```powershell
cd android
.\gradlew signingReport
```

If still not working, use keytool:
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

---

## Important Notes

### For Production Release:
1. Generate a release keystore:
```powershell
keytool -genkey -v -keystore C:\sandbox\faustina\android\app\release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

2. Get the SHA-1 for release keystore:
```powershell
keytool -list -v -keystore C:\sandbox\faustina\android\app\release-keystore.jks -alias release
```

3. Create a new OAuth client ID in Google Cloud Console with the release SHA-1

4. Update your `build.gradle.kts` with proper signing configuration

### Privacy & Security:
- The app uses `appDataFolder` scope which means data is stored privately in the user's Google Drive
- Only the app can access this data
- Users cannot see these files in their normal Drive interface

### Data Sync:
- Backup files are stored as `finance_tracker_backup` in Google Drive AppData folder
- Each sync overwrites the previous backup
- Restore will clear local data and replace it with cloud data

---

## Verification Checklist

- [ ] Google Cloud project created
- [ ] Google Drive API enabled
- [ ] OAuth consent screen configured
- [ ] Android OAuth client ID created with correct SHA-1
- [ ] `build.gradle.kts` updated with Client ID
- [ ] `AndroidManifest.xml` has Google Play services metadata
- [ ] App runs without errors
- [ ] Google Sign-In works
- [ ] Sync and Restore functions work

---

## Support

If you encounter issues not covered here:
1. Check Flutter and Google Sign-In plugin documentation
2. Verify all steps are completed correctly
3. Check the app logs for specific error messages
4. Ensure your Google account has Drive access enabled
