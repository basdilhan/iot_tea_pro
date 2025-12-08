# APK Build and Installation Guide for Production

## Step 1: Build the APK (Release Mode)

Run the following command to build the production APK:

```bash
cd c:\iot\tea_leaf_app_v2
flutter build apk --release
```

**What this does:**
- Compiles your Flutter app in release mode (optimized, no debug info)
- Signs the APK with your default Flutter debug key
- Creates an optimized APK file (~50-80MB typically)

**Build time:** 5-15 minutes (first time takes longer)

### Expected Output Location:
```
c:\iot\tea_leaf_app_v2\build\app\outputs\flutter-apk\app-release.apk
```

---

## Step 2: Locate the Built APK

After successful build, find the APK file:

```
c:\iot\tea_leaf_app_v2\build\app\outputs\flutter-apk\app-release.apk
```

**Copy this file to your computer's Desktop or Downloads folder for easy access:**
```
Copy: c:\iot\tea_leaf_app_v2\build\app\outputs\flutter-apk\app-release.apk
To: C:\Users\[YourUsername]\Downloads\app-release.apk
```

---

## Step 3: Transfer APK to Android Device

Choose one of these methods:

### Method A: Using USB Cable (Recommended)
1. Connect Android phone to your computer via USB cable
2. Enable **Developer Mode** on phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Go back, you'll see "Developer Options" in Settings

3. Enable **USB Debugging**:
   - Settings > Developer Options > USB Debugging (toggle ON)

4. Copy APK file to phone:
   - Open File Explorer on your PC
   - Navigate to: `c:\iot\tea_leaf_app_v2\build\app\outputs\flutter-apk\app-release.apk`
   - Right-click > Copy
   - Open "Phone" or "This PC" > Phone Storage
   - Paste the APK file

OR use ADB command:
```bash
adb push c:\iot\tea_leaf_app_v2\build\app\outputs\flutter-apk\app-release.apk /sdcard/Download/
```

### Method B: Using Email
1. Attach `app-release.apk` to an email
2. Send to yourself or team members
3. Download on the Android phone
4. Open the Downloads app to see the file

### Method C: Using Cloud Storage
1. Upload APK to Google Drive, Dropbox, or OneDrive
2. Share the link with team members
3. Download directly on Android phone

---

## Step 4: Install APK on Android Phone

### Option 1: Direct Installation (Easiest)
1. Locate the APK file on your phone (usually in Downloads)
2. Tap the APK file
3. Android will ask for permission to install
4. Tap "Install"
5. Wait for installation to complete
6. Tap "Open" to launch the app

### Option 2: Using ADB
```bash
adb install c:\iot\tea_leaf_app_v2\build\app\outputs\flutter-apk\app-release.apk
```

### Option 3: Unknown Sources (If APK Won't Install)
If you get "Cannot install" error:
1. Go to Settings > Security
2. Enable "Unknown Sources" or "Install unknown apps"
3. For Chrome/Downloads: Settings > Apps > Chrome > Permissions > Files > Allow
4. Try installing again

---

## Step 5: Verify Installation

1. Look for "iot_tea" or "Tea Weigher" app on your home screen
2. Tap to launch the app
3. You should see:
   - Onboarding screen (first time only)
   - Role selection screen (Manager/Worker)
   - Login screen

---

## Step 6: Test OTP Functionality

### For Worker Login (Real SMS Testing):
1. Select "Tea Leaf Worker" role
2. Enter your phone number: **+94XXXXXXXXX** (Must start with +94)
3. Tap "Send OTP"
4. **You should receive an SMS** with the OTP code
5. Enter the code in the app
6. You'll be logged in and see your worker dashboard

### Troubleshooting SMS Not Received:
- ✅ Ensure phone number is in format: **+94XXXXXXXXX**
- ✅ Wait 1-2 minutes for SMS to arrive
- ✅ Check your phone's internet connection (WiFi or Mobile data)
- ✅ Verify the worker exists in Firebase database with that phone number
- ✅ Check Firebase allows SMS (may have daily limits on free tier)

---

## Important Notes for Production

### 1. Signing APK with Production Key (Optional)
The current APK uses Flutter's default debug key. For production/Play Store:

```bash
flutter build apk --release --obfuscate --split-per-abi
```

This creates:
- `app-armeabi-v7a-release.apk` (for older phones)
- `app-arm64-v8a-release.apk` (for newer phones)
- `app-x86_64-release.apk` (for tablets/emulators)

### 2. Firebase Limits
- **Free Tier**: 100 SMS per day
- If exceeded, wait until next day or upgrade Firebase plan

### 3. Phone Number Format
- **Only accepts**: +94XXXXXXXXX (Sri Lanka format)
- Must be registered in Firebase database under `/workers`

### 4. First App Run
- App will show onboarding screen first time
- Complete onboarding to proceed to login
- Onboarding is skipped on subsequent launches

---

## Quick Reference Commands

```bash
# Build APK
flutter build apk --release

# Install on connected phone via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Install and run directly
flutter install --release

# View connected devices
adb devices

# Clear Flutter cache and rebuild
flutter clean && flutter pub get && flutter build apk --release
```

---

## Support

If you encounter issues:

1. **APK won't build**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **App crashes on launch**:
   - Check Firebase is initialized
   - Verify google-services.json is in `android/app/`
   - Check logcat: `adb logcat | grep flutter`

3. **OTP not received**:
   - Verify phone number format (+94XXXXXXXXX)
   - Check worker exists in Firebase
   - Ensure mobile data/WiFi is connected
   - Wait 1-2 minutes for SMS

---

**Last Updated:** December 8, 2025
**App:** Tea Leaf Management System v2
**Platform:** Flutter (Android)
