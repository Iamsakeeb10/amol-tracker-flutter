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
    project.evaluationDependsOn(":app")
    // home_widget-0.9.3 sets Kotlin JVM 1.8 but depends on glance-appwidget 1.1.1 (JVM 11).
    // Raise its Kotlin target so inline bytecode from Glance can be consumed.
    plugins.withId("org.jetbrains.kotlin.android") {
        if (project.name == "home_widget") {
            afterEvaluate {
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                    compilerOptions {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
                    }
                }
            }
        }
    }
}

// home_widget pulls glance-appwidget:1.+ which resolves to 1.3.0-alpha (SDK 37 + AGP 9.1).
// Our widget uses RemoteViews only; pin Glance to a stable release for compileSdk 36.
subprojects {
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.glance:glance-appwidget:1.1.1")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
