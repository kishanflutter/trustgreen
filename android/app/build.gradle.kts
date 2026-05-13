plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.trustgreen"
    // mobile_scanner 6.x requires compileSdk 36; pin explicitly instead
    // of inheriting the Flutter 3.29 default (35).
    compileSdk = 36

    // Pin NDK r27 explicitly — newer than the Flutter 3.29 default
    // (26.3.11579264) and what mobile_scanner / webview_flutter expect.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.trustgreen"
        // flutter_secure_storage's EncryptedSharedPreferences needs API 23+.
        // mobile_scanner 6.x also requires API 21+. 23 is the safe floor.
        minSdk = 23
        // Target the same SDK we compile against.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
