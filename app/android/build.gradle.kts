import com.android.build.gradle.BaseExtension
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.configureEach {
        resolutionStrategy {
            // 避免传递依赖拉高到需 AGP 8.9.1+ 的版本（本机构建暂用 AGP 8.7 + Gradle 8.9）
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.core:core:1.13.1")
            force("androidx.browser:browser:1.8.0")
            force("androidx.activity:activity:1.9.3")
            force("androidx.activity:activity-ktx:1.9.3")
        }
    }
}

// 与 Flutter 模板一致：把 Gradle 产物放到 <flutter-project>/build/，供 flutter build apk 发现 APK
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    afterEvaluate {
        extensions.findByType(BaseExtension::class.java)?.ndkVersion =
            "29.0.14206865"
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
