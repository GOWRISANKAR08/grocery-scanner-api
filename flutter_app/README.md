# Grocery Scanner – Flutter app

    flutter create . --project-name grocery_scanner   # generates android/ ios/ folders (keeps lib/ & pubspec)
    flutter pub get
    flutter run

Set `baseUrl` in lib/services/api.dart.

## Android: android/app/src/main/AndroidManifest.xml
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <application android:usesCleartextTraffic="true" ...>   <!-- dev only, http -->

Also set minSdkVersion 21 in android/app/build.gradle.

## iOS: ios/Runner/Info.plist
    <key>NSCameraUsageDescription</key><string>Camera is used to scan product barcodes</string>
