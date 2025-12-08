# Firebase Phone Authentication Setup Guide

## ⚠️ Error: "operation-not-allowed"

This error means **Phone Authentication is NOT enabled** in your Firebase project, even if you think you enabled it.

---

## 🔧 Step-by-Step Fix

### Step 1: Enable Phone Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **`iot_tea`**
3. Click on **Authentication** in the left sidebar
4. Click on **Sign-in method** tab
5. Find **Phone** in the list of providers
6. Click on it and **Enable** it (toggle should turn green)
7. Click **Save**

### Step 2: Download Updated google-services.json

**CRITICAL:** After enabling Phone Auth, the configuration file MUST be updated!

1. In Firebase Console, click the **⚙️ Settings icon** → **Project settings**
2. Scroll down to **"Your apps"** section
3. Find your Android app: `com.example.iot_tea`
4. Click the **"Download google-services.json"** button
5. Save the file

### Step 3: Replace the Configuration File

1. Navigate to your project folder:
   ```
   c:\iot\tea_leaf_app_v2\android\app\
   ```

2. **Replace** the existing `google-services.json` file with the newly downloaded one

3. **IMPORTANT:** Make sure the file is named exactly `google-services.json` (not `google-services(1).json` or similar)

### Step 4: Clean and Rebuild

1. Open terminal in project root
2. Run these commands:
   ```bash
   cd android
   ./gradlew clean
   ./gradlew assembleDebug
   ```

3. Or use the full command:
   ```bash
   cd c:/iot/tea_leaf_app_v2/android && bash -c "./gradlew clean && ./gradlew assembleDebug" && cp c:/iot/tea_leaf_app_v2/android/app/build/outputs/apk/debug/app-debug.apk c:/iot/tea_leaf_app_v2/build/app/outputs/flutter-apk/app-debug.apk && "C:/Users/samudu/AppData/Local/Android/Sdk/platform-tools/adb.exe" -s R94XB0FWFJX install -r "c:/iot/tea_leaf_app_v2/build/app/outputs/flutter-apk/app-debug.apk"
   ```

### Step 5: Test Phone Authentication

1. Open the app
2. Select **Worker** role
3. Enter phone number in format: `+94769798081`
4. Click **SEND OTP**
5. Check for SMS code
6. Enter the 6-digit code

---

## 📱 Phone Number Format

**Correct format:** `+94XXXXXXXXX` (country code + number)

Examples:
- ✅ `+94769798081`
- ✅ `+94712345678`
- ❌ `0769798081` (missing country code)
- ❌ `94769798081` (missing + sign)

---

## 🐛 Troubleshooting

### Issue 1: Still getting "operation-not-allowed" error

**Solution:**
- Double-check that Phone provider is **Enabled** (green toggle) in Firebase Console
- Make sure you downloaded the **NEW** `google-services.json` AFTER enabling Phone Auth
- Verify the file was replaced in `android/app/` directory
- Clean and rebuild the app completely

### Issue 2: "SMS quota exceeded"

**Solution:**
- Firebase has a daily SMS quota limit on free plans
- Wait 24 hours or upgrade to Blaze plan
- Or add test phone numbers in Firebase Console (no SMS sent)

### Issue 3: "App not authorized"

**Solution:**
- Your `google-services.json` file doesn't match your Firebase project
- Re-download from the correct Firebase project
- Make sure the package name in Firebase matches: `com.example.iot_tea`

### Issue 4: No SMS received

**Possible causes:**
1. Phone number format incorrect (must include `+94`)
2. Phone number not registered as worker in Firebase Database
3. SMS quota exceeded
4. Network/carrier issues

**Solution:**
- Verify phone number format
- Check Firebase Realtime Database → `/workers` → verify worker has `phone_number` field
- Try adding test phone numbers in Firebase Console → Authentication → Add test phone number

---

## 🧪 Testing with Test Phone Numbers

For development without using real SMS:

1. Firebase Console → Authentication → Sign-in method → Phone
2. Scroll to **"Phone numbers for testing"**
3. Add test number and verification code:
   - Number: `+94111111111`
   - Code: `123456`
4. Click **Add**
5. In app, use `+94111111111` and enter code `123456`

---

## ✅ What Was Fixed in Latest Build

1. ✅ **Onboarding Screen Flow**
   - Onboarding now shows ONLY on first app launch
   - After logout, goes directly to Role Selection screen
   - Onboarding flag preserved across logins/logouts

2. ✅ **Dashboard UI Fixes**
   - Fixed "BOTTOM OVERFLOWED" errors
   - Increased grid aspect ratio to 1.15
   - Better spacing and padding

3. ✅ **Text Color Issues**
   - Dashboard title adapts to light/dark theme
   - Subtitle uses theme-appropriate colors
   - All stat cards now readable in both themes

4. ✅ **Farmer Names in Pie Chart**
   - Legend now shows: "Farmer Name (XX.X kg)"
   - Top farmers displayed with weight
   - Better identification of contributors

5. ✅ **Enhanced Error Messages**
   - Specific error code for `operation-not-allowed`
   - Step-by-step instructions in error message
   - Detailed console logging for debugging

---

## 📋 Checklist Before Testing

- [ ] Phone Authentication **Enabled** in Firebase Console (green toggle)
- [ ] Downloaded **NEW** `google-services.json` file
- [ ] Replaced file in `c:\iot\tea_leaf_app_v2\android\app\google-services.json`
- [ ] Ran `gradlew clean`
- [ ] Ran `gradlew assembleDebug`
- [ ] Installed app on device
- [ ] Worker phone number exists in Firebase Database `/workers`
- [ ] Phone number includes `+94` country code

---

## 🔍 Debug Mode

The app now prints detailed error information:

**In terminal or logcat, you'll see:**
```
=== FIREBASE AUTH ERROR ===
Error code: operation-not-allowed
Error message: This operation is not allowed...
========================
```

**On screen, you'll see:**
- Error message with step-by-step fix instructions
- Error code at the bottom
- Suggestion to check Firebase Console

---

## 📞 Contact & Support

If issues persist after following this guide:

1. **Check Console Logs:** Run `flutter run` and check terminal output
2. **Verify Firebase Setup:** 
   - Project name correct
   - Package name matches: `com.example.iot_tea`
   - Phone Auth enabled
3. **Share Error Details:**
   - Error code from screen
   - Console output from terminal
   - Screenshot of Firebase Console Phone Auth settings

---

**Last Updated:** November 19, 2025
**App Version:** Latest build with Phone Auth fixes
