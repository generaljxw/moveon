allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // 强制所有插件子项目使用 compileSdk 34+，解决 flutter_tts 等旧插件
    // 因 compileSdkVersion=31 导致的 AAR metadata 检查失败
    afterEvaluate {
        @Suppress("DEPRECATION")
        val androidExt = project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        if (androidExt != null) {
            val compileSdk = androidExt.compileSdkVersion
            if (compileSdk != null && compileSdk.startsWith("android-")) {
                val sdkNum = compileSdk.substring(8).toIntOrNull()
                if (sdkNum != null && sdkNum < 34) {
                    androidExt.compileSdkVersion("android-34")
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
