# SSL Commerz Payment Plugin - Troubleshooting Guide

## Error: MissingPluginException

```
MissingPluginException(No implementation found for method initiateSSLCommerz on channel flutter_sslcommerz)
```

### What This Means
The flutter_sslcommerz plugin's native implementation is not available on your current platform.

### Causes & Solutions

#### 1. ❌ Running on Web/Desktop
**Problem:** The flutter_sslcommerz plugin only works on Android and iOS

**Solution:** 
- Test on Android device or emulator
- Do NOT try to run on web or Windows

#### 2. ❌ Android Emulator Without Play Services
**Problem:** Some emulators don't have Google Play Services

**Solution A - Use Google Play Emulator:**
```bash
# In Android Studio, create emulator with Google Play option
# Device: Pixel 4/5/6 etc.
# API: 31+ (Android 12+)
# Variant: Google Play system image
```

**Solution B - Use Real Android Device:**
```bash
# Connect Android phone via USB
flutter devices
flutter run
```

#### 3. ❌ Android Minimum SDK Too Low
**Problem:** flutter_sslcommerz requires Android API 21+

**Check in:** `android/app/build.gradle.kts`

```kotlin
minSdk = flutter.minSdkVersion  // Should be ≥21
```

#### 4. ❌ Plugin Not Installed Properly

**Solution:**
```bash
cd gearshare
flutter clean
flutter pub get
flutter pub upgrade flutter_sslcommerz
flutter run
```

#### 5. ❌ Gradle Build Not Completed
**Problem:** Native code wasn't compiled

**Solution:**
```bash
cd gearshare/android
./gradlew clean
./gradlew build
cd ..
flutter run
```

### Testing Steps

#### Step 1: Check Platform
```bash
flutter run -v
```
Look for `✓ APK`. Should be Android, NOT web or Windows.

#### Step 2: Check Device
```bash
flutter devices
```
Should show:
```
• Android device  
• Pixel 4 (online)
```

NOT:
```
• Web (Windows) (web)  
• Linux (web)
```

#### Step 3: Clean Install
```bash
flutter clean
rm -r android/.gradle
flutter pub get
flutter run
```

#### Step 4: Try Release Build
```bash
flutter run --release
```

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| Platform | Android (API 21+) or iOS |
| Device | Real device or emulator with Play Services |
| Flutter | 3.0+ |
| Dart | 2.17+ |

### Environment Check

Run this to diagnose your setup:

```bash
flutter doctor -v
```

Look for:
- ✓ Flutter SDK
- ✓ Android SDK (API 31+)
- ✓ Android Studio (latest)
- ✓ Gradle 8.0+

### For iOS Users

If you're getting this on iOS:

```bash
cd ios
pod repo update
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

### Workaround: Graceful Degradation

The code now handles MissingPluginException gracefully:

```dart
// This will show user-friendly message instead of crashing
"Payment plugin not available on this platform"
```

### Still Not Working?

Try these advanced steps:

```bash
# 1. Update Flutter to latest
flutter upgrade

# 2. Update dependencies
flutter pub upgrade --major-versions

# 3. Rebuild Android native code
cd android
./gradlew clean build
cd ..

# 4. Run verbose for debugging
flutter run -v

# 5. Check logs
adb logcat | grep flutter
```

### Contact SSL Support

If issue persists:
- Email: support@sslcommerz.com
- Phone: +880-2-48314443
- Check pub.dev page for known issues

### Alternative: Use WebView Approach

If native plugin isn't working, we can implement browser-based payment:

```dart
// Future fallback
// Use flutter_webview or url_launcher instead
// But this is less secure
```

---

## Summary

✅ **Working Setup:**
- Android device (Pixel 4+) or Google Play emulator
- Android API 31+
- Clean build with `flutter clean && flutter pub get`
- Run with `flutter run`

❌ **Common Mistakes:**
- Running on web/Windows
- Using regular emulator (need Google Play version)
- Old Android API (< 21)
- Not running clean build

**Status:** Enhanced error handling added. Code will now show helpful message instead of crashing.
