# Tea Leaf App - Important Code Files Documentation

## Overview
This document contains the most important code files from the Tea Leaf Application. These files represent the core functionality of the Flutter application for tea leaf weighing and worker management.

---

## Key Files Index

1. **main.dart** - Main app entry point and theme configuration
2. **auth_wrapper.dart** - Authentication and routing logic
3. **worker_login_screen.dart** - Worker phone authentication with OTP
4. **smart_weigning_screen.dart** - Smart weighing scale integration
5. **log_list_screen.dart** - Weighing history and logs display
6. **worker_dashboard_screen.dart** - Worker dashboard analytics
7. **payment_provider.dart** - Payment calculation logic
8. **theme_provider.dart** - Dark/Light theme management
9. **firebase_options.dart** - Firebase configuration
10. **ui_design.dart** - UI design constants and utilities

---

## 1. main.dart

**Purpose:** Main app entry point, Firebase initialization, and theme configuration

**Key Features:**
- Firebase initialization with DefaultFirebaseOptions
- Multi-provider setup for state management (ThemeProvider, PaymentProvider)
- Light and Dark theme support
- Material Design 3 theme configuration
- Hero animation disabled on web platform
- Tea-themed color scheme (Navy Blue, Brown, Grey)

**Important Classes:**
- `AppTheme` - Static theme color helper methods
- `TeaWeigherApp` - Main MaterialApp widget
- Theme building methods for Light and Dark themes

---

## 2. auth_wrapper.dart

**Purpose:** Authentication wrapper that manages app routing based on user state

**Key Features:**
- Onboarding screen management
- Authentication state checking
- Role-based navigation (Admin, Collector, Worker)
- SharedPreferences for persistence
- Smooth transitions between auth states

**Flow:**
1. Load onboarding status from SharedPreferences
2. If not completed, show OnboardingScreen
3. Check FirebaseAuth status
4. Route to appropriate screen based on user role

---

## 3. worker_login_screen.dart

**Purpose:** Worker authentication with phone number and OTP verification

**Key Features:**
- Phone number validation (E.164 format)
- Firebase Phone Auth integration
- OTP code verification (6 digits)
- Worker ID validation from Firebase Realtime Database
- SafetyNet/Play Integrity verification support
- Comprehensive error handling with user-friendly messages
- Web support with test OTP mode (123456)
- reCAPTCHA browser redirect handling

**Authentication Flow:**
1. User enters phone number (+94XXXXXXXXX)
2. App validates format and finds matching worker
3. Firebase sends SMS OTP to phone
4. User enters 6-digit OTP
5. App verifies code and logs user in
6. Stores worker ID and user role in SharedPreferences
7. Navigates to WorkerMainScreen

**Error Handling:**
- Invalid phone number format
- Too many verification attempts
- SMS quota exceeded
- Phone Auth not enabled in Firebase
- reCAPTCHA/Play Integrity verification failed

---

## 4. smart_weigning_screen.dart

**Purpose:** Integration with smart weighing scales for real-time data capture

**Key Features:**
- Bluetooth/Serial connection to weighing scale
- Real-time weight display
- Unit selection (kg, lbs)
- Farmer selection from Firebase database
- Scale device identification (SCALE-01)
- Server timestamp integration for accurate logging
- Data storage in Firebase Realtime Database
- Automatic date-based log organization

**Data Structure:**
```
weighing_logs/
  ├── {dateKey}/
  │   ├── Logs_ID_001
  │   │   ├── farmer_id
  │   │   ├── farmer_name
  │   │   ├── weight
  │   │   ├── unit
  │   │   ├── timestamp (ServerValue.timestamp - milliseconds)
  │   │   └── device_id
```

---

## 5. log_list_screen.dart

**Purpose:** Display weighing history and logs with search and filtering

**Key Features:**
- Date picker for historical data viewing
- Search by farmer name
- Real-time log updates from Firebase
- Weight sorting (newest first)
- Earnings calculation based on weight
- Timestamp display formatting (corrected for milliseconds)
- Supports multiple devices/scales
- Payment status display

**Timestamp Handling:**
- Firebase stores timestamps in milliseconds
- Converted to DateTime using `fromMillisecondsSinceEpoch()`
- Displayed in format: `hh:mm:ss a` (e.g., "11:24:07 AM")

---

## 6. worker_dashboard_screen.dart

**Purpose:** Worker dashboard with analytics, recent records, and navigation

**Key Features:**
- Recent weighing records display
- Total earnings calculation
- Daily/Weekly analytics
- Farmer list with contact information
- Real-time data sync from Firebase
- Bottom navigation for easy access
- Worker performance metrics
- Earnings trends

**Navigation Tabs:**
- Dashboard (home)
- Records/Logs
- Farmers/Contacts
- Analytics/Reports
- Settings/Profile

---

## 7. payment_provider.dart

**Purpose:** Payment calculation and pricing logic

**Key Features:**
- Dynamic price per kg from Firebase
- Earnings calculation based on weight
- Bonus calculation (if applicable)
- Currency formatting (LKR/Rs)
- Provider pattern for state management
- Automatic price loading on app startup
- Real-time price updates

**Calculation Logic:**
```
Earnings = Weight (kg) × Price per kg
Total Earnings = Sum of all earnings
```

---

## 8. theme_provider.dart

**Purpose:** Theme state management (Dark/Light mode)

**Key Features:**
- Toggle between dark and light themes
- Persist theme preference in SharedPreferences
- ChangeNotifier for reactive updates
- Default theme based on system preferences
- Smooth theme transitions
- Apply theme to all UI elements

**Theme Variables:**
- `isDarkMode` - Boolean flag for current theme
- Notifies listeners on theme change

---

## 9. firebase_options.dart

**Purpose:** Firebase configuration for different platforms

**Key Features:**
- Platform-specific Firebase credentials
- Project ID: tealeafpro
- API Keys and authentication configurations
- App IDs for Android/iOS/Web
- Database URLs
- Storage configurations

**Platforms Supported:**
- Android (com.example.iot_tea)
- iOS (com.example.iotTea)
- Web

**Database URL:**
```
https://tealeafpro-default-rtdb.firebaseio.com
```

---

## 10. ui_design.dart

**Purpose:** Centralized UI design constants and helper functions

**Key Features:**
- Color palettes (Tea-themed: Navy, Brown, Grey)
- Typography configurations
- Spacing and padding constants
- Border radius values
- Shadow definitions
- Common widget styling
- Platform-specific UI adjustments

**Color Scheme:**
- Primary: Navy Blue (#1A365D, #4A90E2)
- Secondary: Brown (#8B4513, #CD853F)
- Accent: Grey (#4B5563, #6B7280)
- Background: Light (#F7FAFC) / Dark (#1F2937)

---

## Firebase Realtime Database Structure

```
root/
├── workers/
│   ├── {workerId}
│   │   ├── phone_number: "+94XXXXXXXXX"
│   │   ├── name: "Worker Name"
│   │   ├── active: true
│   │   └── role: "worker"
├── weighing_logs/
│   ├── {dateKey} (YYYY-MM-DD)
│   │   ├── Logs_ID_001
│   │   │   ├── farmer_id: "ID123"
│   │   │   ├── farmer_name: "Farmer Name"
│   │   │   ├── weight: 25.5
│   │   │   ├── unit: "kg"
│   │   │   ├── timestamp: 1702115047000 (milliseconds)
│   │   │   └── device_id: "SCALE-01"
└── price_per_kg: 100 (LKR)
```

---

## Authentication Flow Diagram

```
[Login Screen]
    ↓
[Enter Phone Number]
    ↓
[Validate Worker in Database]
    ↓
[Send OTP via Firebase]
    ↓
[reCAPTCHA/SafetyNet Check]
    ↓
[Receive Browser Callback]
    ↓
[Enter OTP Code]
    ↓
[Verify with Firebase]
    ↓
[Store Worker ID & Role]
    ↓
[Navigate to Dashboard]
```

---

## Important Configuration Files

### android/app/build.gradle.kts
- compileSdk: 36
- targetSdk: 34
- minSdk: 24
- Dependencies: Firebase, Google Play Services (SafetyNet, Auth)
- MultiDex enabled for larger APK size

### android/app/src/main/AndroidManifest.xml
- Phone permissions for OTP
- Internet and network permissions
- Firebase Auth reCAPTCHA redirect handler
- Google Maps API key configuration

---

## Key Dependencies (pubspec.yaml)

```yaml
firebase_core: Latest
firebase_auth: Latest
firebase_database: Latest
firebase_storage: Latest
provider: State management
shared_preferences: Local storage
google_maps_flutter: Location mapping
geolocator: GPS integration
intl: Date/Time formatting
charts: Analytics visualization
```

---

## Recent Fixes and Improvements

### 1. Timestamp Display Fix
- **Issue:** Timestamps displayed incorrect times
- **Cause:** Multiplying Firebase milliseconds by 1000
- **Fix:** Removed multiplication; Firebase uses milliseconds directly
- **Files:** log_list_screen.dart, worker_dashboard_screen.dart

### 2. Firebase Phone Auth Setup
- **Issue:** reCAPTCHA/Play Integrity verification failures
- **Cause:** Missing SafetyNet dependencies and incorrect manifest config
- **Fix:** 
  - Added play-services-safetynet dependency
  - Added reCAPTCHA redirect handler in AndroidManifest
  - Configured proper Firebase app credentials

### 3. Android SDK Compatibility
- **Issue:** Plugin compilation failures
- **Fix:** Updated compileSdk to 36 to satisfy plugin requirements

---

## GitHub Repository

**Repository:** https://github.com/basdilhan/iot_tea_pro
**Branch:** main
**Owner:** basdilhan

---

## Development Notes

### Testing Authentication
- Use phone format: +94XXXXXXXXX
- Test numbers can be added in worker_login_screen.dart
- For web development, test OTP is 123456

### Building APK
```bash
flutter build apk --release
```

### Testing on Device
```bash
adb devices
adb install -r path/to/app-debug.apk
```

### Running on Web
```bash
flutter run -d chrome
```

---

## Support and Troubleshooting

### Common Issues

1. **OTP not being received**
   - Check Firebase Phone Auth is enabled
   - Verify phone number format (+94XXXXXXXXX)
   - Ensure VPN is off for Play Integrity check

2. **Timestamp showing wrong time**
   - Already fixed - using Firebase milliseconds directly
   - Verify device timezone is correct

3. **Build failures**
   - Run `flutter clean` and `flutter pub get`
   - Check compileSdk is 36 or higher
   - Verify JAVA_HOME points to JDK 17+

---

## Last Updated: December 11, 2025

For the complete, up-to-date source code, visit the GitHub repository.
