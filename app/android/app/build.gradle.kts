plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter Gradle Plugin（由 Flutter SDK 提供）
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fzy.pangbao"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    signingConfigs {
        create("release") {
            storeFile = rootProject.file("pangbao-upload.jks")
            storePassword = "123456"
            keyAlias = "pangbao-upload"
            keyPassword = "123456"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fzy.pangbao"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
}
