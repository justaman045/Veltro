plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.3" apply false
}

allprojects {
    repositories {
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
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            project.extensions.findByName("android")?.let { ext ->
                try {
                    val method = ext.javaClass.getMethod("setNamespace", String::class.java)
                    // If namespace is null or empty, it will be set, but we just set it blindly for all plugins
                    // A safer approach is to only target isar_flutter_libs
                    if (project.name == "isar_flutter_libs") {
                        method.invoke(ext, "dev.isar.isar_flutter_libs")
                    }
                } catch (e: Exception) {}

                try {
                    ext.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(ext, 35)
                } catch (e: Exception) {
                    try {
                        ext.javaClass.getMethod("setCompileSdkVersion", String::class.java).invoke(ext, "android-35")
                    } catch (ex: Exception) {}
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
