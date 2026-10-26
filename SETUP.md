# Setup for real media (photo_manager + video_player)

## pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  photo_manager: ^3.0.0
  video_player: ^2.8.0
```
Then run `flutter pub get`.

## Android: android/app/src/main/AndroidManifest.xml
Inside `<manifest>` (above `<application>`):
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
```
Also set `minSdkVersion 21` (or higher) in android/app/build.gradle.

## iOS: ios/Runner/Info.plist
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Pick videos and photos to edit.</string>
```

## Vyantra branding
Add the logo to `pubspec.yaml` (keep the two-space indent under `flutter:`):
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/logo.png
```
Put `assets/logo.png` in your project's `assets/` folder.

App name on the home screen:
- Android: in `AndroidManifest.xml` set `android:label="Vyantra"` on `<application>`.
- iOS: in `Info.plist` set `CFBundleDisplayName` to `Vyantra`.

Launcher icon (optional): add `flutter_launcher_icons` and point `image_path` at `assets/logo.png`.
