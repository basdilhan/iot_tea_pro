# 🍃 IoT Tea Pro - Smart Tea Leaf Weighing System

<div align="center">
  
**A comprehensive Flutter application for smart tea leaf weighing, worker management, and real-time analytics**

[![Flutter](https://img.shields.io/badge/Flutter-3.8%2B-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime%20DB-orange?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green)](.)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Firebase Setup](#firebase-setup)
- [Building & Deployment](#building--deployment)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Support](#support)

---

## 🎯 Overview

**IoT Tea Pro** is an intelligent tea leaf management system that revolutionizes the tea industry workflow. It seamlessly integrates IoT weighing scales with a comprehensive mobile application to enable real-time data capture, worker analytics, and payment processing for tea leaf collection operations.

### Key Problem Solved
- Automates manual tea leaf weighing processes
- Provides real-time analytics and worker performance tracking
- Eliminates paperwork and reduces administrative overhead
- Enables transparent payment calculation based on actual weights
- Supports multi-platform deployment (Android, iOS, Web)

---

## ✨ Features

### 👷 Worker Features
- **Phone-based OTP Authentication** - Secure Firebase Phone Auth with SMS verification
- **Smart Weighing Integration** - Real-time connection with IoT weighing scales (SCALE-01)
- **Weight Logging** - Automatic log capture with farmer details, weights, and timestamps
- **Earnings Dashboard** - Real-time earnings calculation based on weight and configurable pricing
- **Analytics & Reports** - Daily/weekly earnings trends and performance metrics
- **Farmer Management** - Access to farmer list with contact information
- **Payment Tracking** - Complete payment history with earnings breakdown

### 📊 Collector/Admin Features
- **Comprehensive Analytics** - Real-time analytics dashboard with charts and reports
- **Worker Management** - Manage worker profiles, roles, and permissions
- **Log Management** - View and manage weighing logs with advanced filtering
- **Payment Settings** - Configure price per kg and manage payment rules
- **Location Tracking** - Google Maps integration for location-based services
- **Reports Generation** - Generate detailed reports for analysis and record-keeping

### 🎨 UI/UX Features
- **Dark/Light Theme Support** - Toggle between dark and light modes
- **Responsive Design** - Optimized for mobile, tablet, and web platforms
- **Real-time Updates** - Firebase Realtime Database for instant data synchronization
- **Tea-themed Design** - Beautiful Material Design 3 with tea-inspired color scheme (Navy, Brown, Grey)

---

## 🏗️ Architecture

The application follows a **provider-based state management pattern** with clean separation of concerns:

```
IoT Tea Pro
├── Presentation Layer (Screens & UI)
├── Business Logic Layer (Providers & Services)
├── Data Layer (Firebase & Local Storage)
└── Utilities & Constants
```

### State Management
- **Provider Pattern** - Used for theme management and payment calculations
- **Firebase Listeners** - Real-time data synchronization
- **SharedPreferences** - Local persistence for user preferences and onboarding state

### Authentication Flow
```
Phone Number → Firebase Auth → OTP Verification → Worker Validation → Dashboard
```

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev) (3.8+)
- **Language**: Dart
- **UI Framework**: Material Design 3
- **State Management**: Provider 6.1.5+
- **Charts**: FL Chart 0.70.0
- **Maps**: Google Maps Flutter 2.6.1

### Backend & Services
- **Authentication**: Firebase Authentication (Phone Auth)
- **Database**: Firebase Realtime Database
- **Infrastructure**: Google Cloud Platform (Firebase)
- **Geolocation**: Geolocator 11.0.0

### Additional Libraries
- **WebView**: WebView Flutter 4.8.0
- **HTTP**: HTTP 1.2.2
- **Localization**: Intl 0.20.2
- **Local Storage**: Shared Preferences 2.5.3
- **Icons**: Cupertino Icons 1.0.8

---

## 📁 Project Structure

```
iot_tea_pro/
├── lib/
│   ├── main.dart                           # App entry point & theme config
│   ├── auth_wrapper.dart                   # Auth state & routing
│   ├── worker_login_screen.dart            # OTP authentication
│   ├── worker_dashboard_screen.dart        # Worker analytics dashboard
│   ├── smart_weigning_screen.dart          # Scale integration & logging
│   ├── log_list_screen.dart                # Weighing history
│   ├── worker_main_screen.dart             # Worker home screen
│   ├── collector_analytics_screen.dart     # Collector dashboard
│   ├── manage_workers_screen.dart          # Worker management
│   ├── map_screen.dart                     # Location mapping
│   ├── payment_provider.dart               # Payment calculations
│   ├── theme_provider.dart                 # Theme management
│   ├── firebase_options.dart               # Firebase config
│   ├── ui_design.dart                      # UI constants & utilities
│   └── ... other screens and utilities
├── android/                                # Android platform code
├── ios/                                    # iOS platform code
├── web/                                    # Web platform code
├── pubspec.yaml                            # Project dependencies
├── firebase.json                           # Firebase configuration
├── analysis_options.yaml                   # Dart lint rules
└── README.md                               # This file

```

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.8+ ([Download](https://flutter.dev/docs/get-started/install))
- Dart SDK (included with Flutter)
- Firebase Account ([Sign up](https://firebase.google.com))
- Android Studio / Xcode (for mobile development)
- Git

### Quick Start

1. **Clone the Repository**
   ```bash
   git clone https://github.com/basdilhan/iot_tea_pro.git
   cd iot_tea_pro
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (see [Firebase Setup](#firebase-setup))

4. **Run the App**
   ```bash
   # Mobile (Android)
   flutter run

   # Web
   flutter run -d chrome

   # iOS
   flutter run -d ios
   ```

---

## 📲 Installation

### Android
```bash
# Build APK
flutter build apk --release

# Or use the provided batch script
build_apk.bat

# Install on device
adb install -r build/app/outputs/apk/release/app-release.apk
```

### iOS
```bash
# Build iOS app
flutter build ios --release

# Or use Xcode
open ios/Runner.xcworkspace
```

### Web
```bash
# Build web version
flutter build web

# Run on local server
flutter run -d chrome
```

---

## ⚙️ Configuration

### Firebase Setup

1. **Create Firebase Project**
   - Visit [Firebase Console](https://console.firebase.google.com)
   - Create a new project named "tealeafpro"

2. **Enable Services**
   - ✅ Realtime Database
   - ✅ Authentication (Phone)
   - ✅ Cloud Firestore (optional)

3. **Configure Platform Support**
   - Register Android app (com.example.iot_tea)
   - Register iOS app (com.example.iotTea)
   - Register Web app

4. **Download Configuration Files**
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

5. **Database Structure**
   ```json
   {
     "workers": {
       "worker_id": {
         "phone_number": "+94XXXXXXXXX",
         "name": "Worker Name",
         "role": "worker",
         "active": true
       }
     },
     "weighing_logs": {
       "YYYY-MM-DD": {
         "Logs_ID_001": {
           "farmer_id": "ID123",
           "farmer_name": "Farmer Name",
           "weight": 25.5,
           "unit": "kg",
           "timestamp": 1702115047000,
           "device_id": "SCALE-01"
         }
       }
     },
     "price_per_kg": 100
   }
   ```

### Environment Variables
No environment variables needed. All configuration is in `firebase_options.dart`.

---

## 💻 Usage

### Worker Workflow
1. **Login** - Enter phone number (+94XXXXXXXXX) and verify with OTP
2. **Dashboard** - View earnings, recent records, and analytics
3. **Weigh Tea** - Connect to smart scale and log weights
4. **Track Earnings** - Monitor payment calculations in real-time
5. **View History** - Check weighing logs by date or farmer

### Admin/Collector Workflow
1. **Login** - Use admin credentials
2. **Manage Workers** - Add, edit, or deactivate workers
3. **View Analytics** - Access comprehensive performance reports
4. **Configure Payment** - Set price per kg and payment rules
5. **Generate Reports** - Export data for accounting/analysis

---

## 🔐 Authentication

### Phone OTP Authentication
- **Format**: E.164 international format (+94XXXXXXXXX)
- **OTP Length**: 6 digits
- **Verification**: Firebase Phone Auth with reCAPTCHA/Play Integrity
- **Web Testing**: Use OTP code `123456` for development

### Security Features
- SafetyNet/Play Integrity API verification on Android
- reCAPTCHA verification on web
- Secure OTP storage with automatic cleanup
- Token-based session management

---

## 📊 Database Schema

### Realtime Database
```
firebase_root/
├── workers/
│   └── {workerId}
│       ├── phone_number: string
│       ├── name: string
│       ├── role: "admin|collector|worker"
│       └── active: boolean
├── weighing_logs/
│   └── {YYYY-MM-DD}/
│       └── {logId}
│           ├── farmer_id: string
│           ├── farmer_name: string
│           ├── weight: number
│           ├── unit: "kg|lbs"
│           ├── timestamp: number (milliseconds)
│           └── device_id: string
├── farmers/
│   └── {farmerId}
│       ├── name: string
│       ├── phone: string
│       └── location: string
└── price_per_kg: number
```

---

## 🏗️ Building & Deployment

### Development Build
```bash
flutter build apk --debug
```

### Production Build
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Deployment Steps
See [APK_BUILD_AND_INSTALL_GUIDE.md](APK_BUILD_AND_INSTALL_GUIDE.md) for detailed deployment instructions.

---

## 📚 Documentation

Comprehensive documentation is available:

- **[Tea Leaf App Code Documentation](TEA_LEAF_APP_CODE_DOCUMENTATION.md)** - Detailed explanation of core files and functionality
- **[Firebase Phone Auth Setup Guide](FIREBASE_PHONE_AUTH_SETUP_GUIDE.md)** - Complete Firebase authentication configuration
- **[OTP Firebase Setup](OTP_FIREBASE_SETUP.md)** - OTP-specific setup instructions
- **[APK Build and Install Guide](APK_BUILD_AND_INSTALL_GUIDE.md)** - Building and deploying the application

---

## 🐛 Troubleshooting

### OTP Not Received
- Verify Firebase Phone Auth is enabled
- Check phone number format (+94XXXXXXXXX)
- Ensure VPN is disabled for Play Integrity check
- Verify SMS quota not exceeded in Firebase console

### Build Failures
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade

# Check SDK versions
flutter doctor -v
```

### Timestamp Issues
- Firebase stores timestamps in milliseconds
- App correctly converts using `fromMillisecondsSinceEpoch()`
- Verify device timezone is correct

### Compilation Issues
- Ensure `compileSdk: 36` or higher in `android/app/build.gradle.kts`
- Use JDK 17+ for Java compilation
- Run `flutter upgrade` to update Flutter

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙋 Support

For support, issues, or feature requests:
- Open an issue on [GitHub Issues](https://github.com/basdilhan/iot_tea_pro/issues)
- Check existing documentation in the `/docs` folder
- Review [Tea Leaf App Code Documentation](TEA_LEAF_APP_CODE_DOCUMENTATION.md)

---

## 📱 Screenshots & Demo

(Add your app screenshots here)

---

## 🔗 Resources

- [Flutter Documentation](https://flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Material Design 3](https://m3.material.io)
- [Dart Language Guide](https://dart.dev/guides)

---

## 👨‍💻 Author

**basdilhan**  
GitHub: [@basdilhan](https://github.com/basdilhan)

---

<div align="center">

**Made with ❤️ for the tea industry**

[⬆ Back to Top](#-iot-tea-pro---smart-tea-leaf-weighing-system)

</div>
