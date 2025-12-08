# Firebase Phone Authentication Setup Guide

## Current Status

✅ **Web Development**: Works with test OTP `123456`
❌ **Mobile App**: Real SMS requires proper Firebase configuration

---

## For Real SMS on Mobile Device

### Step 1: Generate SHA Fingerprints

Run this command in your project directory:

```bash
cd android
./gradlew signingReport
```

You'll get output like:
```
Task :app:signingReport
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\keystore
Alias: androiddebugkey
MD5: XX:XX:XX:XX
SHA1: 6F:AF:5F:64:4C:9C:8A:EB:6E:EA:E0:5F:9E:0D:AF:2B:E3:AF:D5:90
SHA-256: A5:73:DB:1A:D2:6E:89:0D:4B:D9:95:08:6C:C6:20:C8:AC:4D:DA:EB:E0:F3:7E:15:82:6E:84:5A:15:E0:B9:61
```

**Copy the SHA1 and SHA-256 values**

---

### Step 2: Add Fingerprints to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (tea_leaf_app_v2)
3. Click **Project Settings** (gear icon, top left)
4. Go to **Your apps** tab
5. Select your **Android app**
6. Scroll to **SHA certificate fingerprints** section
7. Click **Add fingerprint**
8. Paste your **SHA1** value and click **Save**
9. Click **Add fingerprint** again
10. Paste your **SHA-256** value and click **Save**

---

### Step 3: Download New google-services.json

1. In Firebase Console, stay in Project Settings
2. Under **Your apps**, next to your Android app, click the **Download** button
3. Save the file
4. Replace the old file:
   - Delete: `android/app/google-services.json`
   - Move the new file to: `android/app/google-services.json`

---

### Step 4: Rebuild and Install on Phone

```bash
# Clean previous builds
flutter clean

# Build release APK
flutter build apk --release

# Install on connected phone
flutter install --release
```

Or with Android Studio:
```bash
flutter run --release
```

---

### Step 5: Test Real SMS

1. Install the app on your Android phone
2. Go to login screen
3. Enter a registered worker's phone number (e.g., `+94775689694`)
4. Click "Send OTP"
5. **You should receive an SMS** with the OTP code
6. Enter the OTP and login

---

## Troubleshooting

### If SMS still doesn't arrive:

1. **Check Firebase Console**:
   - Go to Authentication > Phone
   - Verify "Phone" provider is **Enabled**

2. **Verify Phone Numbers in Database**:
   - Check `/workers/{workerId}/phone_number` exists
   - Ensure format is `+94XXXXXXXXX` (with country code)

3. **Check Quota**:
   - Firebase free tier has SMS limits
   - Go to Quotas in Firebase Console
   - Verify you haven't exceeded daily SMS limit

4. **Google Play Services**:
   - Ensure Google Play Services is installed on test phone
   - Disable VPN if testing

---

## Current Database Worker Phone Numbers

You can use these for testing:

```
Worker 9798: +94769798081
Worker 9012: +94775689694
```

---

## Web Development Notes

For testing on Chrome/Web:
- ✅ Use test OTP: `123456`
- ✅ Any registered phone number works
- ❌ Real SMS not available (reCAPTCHA requires Enterprise setup)

To make web SMS work (advanced):
- Set up Firebase reCAPTCHA Enterprise
- Enable phone auth in Firebase Console
- Add domain to authorized domains
- Configure reCAPTCHA keys in app config

---

## Key Files Modified

- `lib/worker_login_screen.dart` - Added web OTP bypass + null-safe handling
- `lib/dashboard_screen.dart` - Fixed timestamp null safety
- `lib/log_list_screen.dart` - Fixed timestamp sorting
- `android/app/google-services.json` - **MUST be updated with new fingerprints**

---

## Support

If real SMS doesn't work after these steps:
1. Check Firebase Console for error messages
2. Verify all SHA fingerprints are added correctly
3. Ensure phone number format is `+94XXXXXXXXX`
4. Try with a different phone number
5. Check Firebase billing to ensure SMS is enabled
