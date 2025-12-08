# TODO: Integrate Google Maps via Python Server in Flutter App

## Steps to Complete

- [x] Create Python Flask server (server.py) to serve Google Maps HTML page
- [x] Add webview_flutter dependency to pubspec.yaml
- [x] Modify map_screen.dart to use WebView and communicate with server
- [x] Test the integration by running server and app

# TODO: Fix Flutter APK Build Errors

## Steps to Complete

- [ ] Increase Gradle JVM memory settings in android/gradle.properties (MaxMetaspaceSize to 512m, heap to 2048M)
- [ ] Clean Flutter build cache
- [ ] Stop Gradle daemon
- [ ] Retry APK build for android-arm64 release
