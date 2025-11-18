# Quick Reference Commands

## Get SHA-1 Fingerprint

### Method 1: Using Gradle (Recommended)
```powershell
cd C:\sandbox\faustina\android
.\gradlew signingReport
```

### Method 2: Using Keytool
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

---

## Flutter Commands

### Clean and Rebuild
```powershell
flutter clean
flutter pub get
flutter run
```

### Check for Issues
```powershell
flutter doctor
flutter analyze
```

### Run on Specific Device
```powershell
flutter devices
flutter run -d <device-id>
```

---

## Google Cloud Console Links

- **Console Home**: https://console.cloud.google.com/
- **APIs & Services**: https://console.cloud.google.com/apis/dashboard
- **Credentials**: https://console.cloud.google.com/apis/credentials
- **OAuth Consent Screen**: https://console.cloud.google.com/apis/credentials/consent

---

## Testing Cloud Sync

1. **Build and Run**:
   ```powershell
   flutter run
   ```

2. **Navigate to**: Settings/Menu → Cloud Sync

3. **Test Flow**:
   - Click "Sign in with Google"
   - Grant permissions
   - Click "Sync Now" to backup
   - Click "Restore Data" to test restore

---

## Troubleshooting

### If Sign-In Fails:

1. **Check SHA-1 is correct**:
   ```powershell
   cd android
   .\gradlew signingReport
   ```

2. **Uninstall and reinstall app**:
   ```powershell
   flutter clean
   flutter run
   ```

3. **Wait 5-10 minutes** after updating Google Cloud Console

### If Build Fails:

```powershell
flutter clean
cd android
.\gradlew clean
cd ..
flutter pub get
flutter run
```

---

## Important Files

- `CLOUD_SYNC_SETUP.md` - Complete setup guide
- `CONFIGURATION_TEMPLATE.md` - Quick config reference
- `lib/services/cloud_sync_service.dart` - Cloud sync implementation
- `lib/screens/cloud_sync_page.dart` - Cloud sync UI
- `android/app/build.gradle.kts` - Add Client ID here
- `android/app/src/main/AndroidManifest.xml` - Already configured ✓
