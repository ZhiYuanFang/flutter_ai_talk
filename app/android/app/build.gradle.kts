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
// 可选：从 AppGallery Connect 的 agconnect-services.json 解析华为 app_id。
val hmsAppIdFromAgconnect = agconnectServicesFile.takeIf { it.exists() }?.readText()
    ?.let { text -> Regex(""""app_id"\s*:\s*"([^"]+)"""").find(text)?.groupValues?.get(1) }
    ?.trim()
    ?: ""

// china_push manifestPlaceholders：空字符串表示该厂商未开通（插件可能回落到小米）。
val hmsAppId = hmsAppIdFromAgconnect.ifEmpty { pushProp("ucg.hms.app_id") }
val miAppId = pushProp("ucg.mipush.app_id")
val miAppKey = pushProp("ucg.mipush.app_key")
val oppoAppKey = pushProp("ucg.oppo.app_key")
val oppoAppSecret = pushProp("ucg.oppo.app_secret")
val vivoAppId = pushProp("ucg.vivo.app_id")
val vivoAppKey = pushProp("ucg.vivo.app_key")
val honorAppId = pushProp("ucg.honor.app_id")

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

        // china_push 插件 AndroidManifest 占位符（见包 README）
        manifestPlaceholders["MI_APP_ID"] = miAppId
        manifestPlaceholders["MI_APP_KEY"] = miAppKey
        manifestPlaceholders["OPPO_APP_KEY"] = oppoAppKey
        manifestPlaceholders["OPPO_APP_SECRET"] = oppoAppSecret
        manifestPlaceholders["VIVO_APP_ID"] = vivoAppId
        manifestPlaceholders["VIVO_APP_KEY"] = vivoAppKey
        manifestPlaceholders["HONOR_APP_ID"] = honorAppId
        manifestPlaceholders["HMS_APP_ID"] = hmsAppId

        // 纯数字 meta-data 会被 PackageManager 存成 Integer，china_push 的 getString 会 ClassCast→null。
        // 经 @string 注入，保证 Bundle 里是 String。
        resValue("string", "china_push_hms_app_id", hmsAppId)
        resValue("string", "china_push_mi_app_id", miAppId)
        resValue("string", "china_push_mi_app_key", miAppKey)
        resValue("string", "china_push_honor_app_id", honorAppId)
        // HMS SDK 自身读 com.huawei.hms.client.appid（格式 appid=数字），与 china_push 的 HMS_APP_ID 不同键。
        resValue("string", "huawei_hms_client_appid", if (hmsAppId.isEmpty()) "" else "appid=$hmsAppId")
        val hmsCpId = agconnectServicesFile.takeIf { it.exists() }?.readText()
            ?.let { text -> Regex(""""cp_id"\s*:\s*"([^"]+)"""").find(text)?.groupValues?.get(1) }
            ?.trim()
            ?: ""
        resValue("string", "huawei_hms_client_cpid", if (hmsCpId.isEmpty()) "" else "cpid=$hmsCpId")
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

// china_push XML 使用 \${PLACEHOLDER}；AGP 只替换 ${PLACEHOLDER}，会留下前导 '\'。
// 不依赖 AGConnect 插件 / assets 内 JSON：china_push 经 meta-data HMS_APP_ID 注入 getToken。
// process*Manifest 产出路径因 AGP 版本而异，故在相关任务结束后扫 intermediates 兜底剥离。
fun stripChinaPushManifestBackslash(manifestFile: java.io.File) {
    if (!manifestFile.isFile) return
    val original = manifestFile.readText(Charsets.UTF_8)
    val fixed = original.replace(Regex("""(android:value=")\\"""), "$1")
    if (fixed != original) {
        manifestFile.writeText(fixed, Charsets.UTF_8)
        logger.lifecycle("china_push: stripped meta-data backslash in ${manifestFile.path}")
    }
}

fun stripAllAppManifestsUnderBuild() {
    val intermediates = layout.buildDirectory.dir("intermediates").get().asFile
    if (!intermediates.isDirectory) return
    intermediates.walkTopDown()
        .filter { it.isFile && it.name == "AndroidManifest.xml" }
        .forEach { stripChinaPushManifestBackslash(it) }
}

listOf(
    "processDebugMainManifest",
    "processReleaseMainManifest",
    "processDebugManifest",
    "processReleaseManifest",
    "processDebugManifestForPackage",
    "processReleaseManifestForPackage",
).forEach { taskName ->
    tasks.matching { it.name == taskName }.configureEach {
        doLast { stripAllAppManifestsUnderBuild() }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.core:core-splashscreen:1.0.1")
    // 小米 / OPPO / vivo AAR：china_push 为 compileOnly，须由宿主提供运行时依赖
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar", "*.aar"))))
    implementation("org.bouncycastle:bcprov-jdk15on:1.70")
}
