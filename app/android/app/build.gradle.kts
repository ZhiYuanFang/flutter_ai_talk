import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter Gradle Plugin（由 Flutter SDK 提供）
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val pushPropertiesFile = rootProject.file("push.properties")
val pushProperties = Properties()
if (pushPropertiesFile.exists()) {
    FileInputStream(pushPropertiesFile).use { pushProperties.load(it) }
}

fun pushProp(key: String, default: String = ""): String =
    pushProperties.getProperty(key)?.trim()?.takeIf { it.isNotEmpty() } ?: default

val agconnectServicesFile = file("agconnect-services.json")
// Optional: copy agconnect-services.json from AppGallery Connect for HMS app_id auto-discovery.
// AGConnect Gradle plugin is not required; app_id is read below or via push.properties.

val hmsAppIdFromAgconnect = agconnectServicesFile.takeIf { it.exists() }?.readText()
    ?.let { text -> Regex(""""app_id"\s*:\s*"([^"]+)"""").find(text)?.groupValues?.get(1) }
    ?.trim()
    ?: ""

val hmsAppId = hmsAppIdFromAgconnect.ifEmpty { pushProp("ucg.hms.app_id") }
val mipushAppId = pushProp("ucg.mipush.app_id")
val mipushAppKey = pushProp("ucg.mipush.app_key")
val mipushRegion = pushProp("ucg.mipush.region", "China")

// MiPush SDK is distributed as a local AAR from https://admin.xmpush.xiaomi.com/
val mipushAarFiles = file("libs").listFiles()
    ?.filter { it.isFile && it.name.startsWith("MiPush_SDK_Client") && it.name.endsWith(".aar") }
    ?: emptyList()
val mipushEnabled = mipushAarFiles.isNotEmpty()

android {
    namespace = "com.fzy.pangbao"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile")!!)
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fzy.pangbao"
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        buildConfigField("String", "UCG_HMS_APP_ID", "\"$hmsAppId\"")
        buildConfigField("String", "UCG_MIPUSH_APP_ID", "\"$mipushAppId\"")
        buildConfigField("String", "UCG_MIPUSH_APP_KEY", "\"$mipushAppKey\"")
        buildConfigField("String", "UCG_MIPUSH_REGION", "\"$mipushRegion\"")
        buildConfigField("boolean", "UCG_MIPUSH_ENABLED", mipushEnabled.toString())

        manifestPlaceholders["UCG_MIPUSH_APP_ID"] = mipushAppId
        manifestPlaceholders["UCG_MIPUSH_APP_KEY"] = mipushAppKey
    }

    buildFeatures {
        buildConfig = true
    }

    sourceSets {
        getByName("main") {
            java.srcDir(
                if (mipushEnabled) "src/mipush/kotlin" else "src/nomipush/kotlin",
            )
            if (mipushEnabled) {
                manifest.srcFile("src/mipush/AndroidManifest.xml")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.core:core-splashscreen:1.0.1")
    implementation("com.huawei.hms:push:6.12.0.300")
    if (mipushEnabled) {
        mipushAarFiles.forEach { aar ->
            implementation(files(aar))
        }
    }
}
