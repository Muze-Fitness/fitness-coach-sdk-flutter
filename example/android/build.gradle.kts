allprojects {
    repositories {
        google()
        mavenCentral()
        mavenLocal()
        maven {
            url = uri("https://maven.pkg.github.com/Muze-Fitness/zing-android-lib")
            credentials {
                username = System.getenv("GPR_USER") ?: (project.findProperty("gpr.user") as String? ?: "")
                password = System.getenv("GPR_KEY") ?: (project.findProperty("gpr.key") as String? ?: "")
            }
        }
    }
}

plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
