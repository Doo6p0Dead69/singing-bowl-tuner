@echo off
REM Build Android debug APK for Singing Bowl Tuner
echo Installing dependencies...
flutter pub get
echo Building debug APK...
flutter build apk --debug
echo.
echo Build complete. APK can be found in build\app\outputs\flutter-apk\app-debug.apk
pause