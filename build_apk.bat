@echo off
echo Cleaning project...
call flutter clean
echo.

echo Getting dependencies...
call flutter pub get
echo.

echo Stopping Gradle daemons...
cd android
call gradlew --stop
cd ..
echo.

echo Building APK (this will take several minutes)...
call flutter build apk --split-per-abi
echo.

echo Build complete! APK location:
echo build\app\outputs\flutter-apk\
pause
