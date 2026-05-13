pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 8.7.3 — current stable for Gradle 8.10.x.
    id("com.android.application") version "8.7.3" apply false
    // Kotlin 2.1.20 — required by mobile_scanner 6.x and webview_flutter
    // plugins that ship with Kotlin 2.1 metadata.
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}

include(":app")
