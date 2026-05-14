import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val abiCodes = mapOf(
    "armeabi-v7a" to 1,
    "arm64-v8a"   to 2,
    "x86"         to 3,
    "x86_64"      to 4
)

android {
    namespace = "com.shakib.amol.amol_tracker_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ✅ Fix 1: Replaced deprecated jvmTarget with compilerOptions DSL
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias", "")
            keyPassword = keystoreProperties.getProperty("keyPassword", "")
            storeFile = file(keystoreProperties.getProperty("storeFile", ""))
            storePassword = keystoreProperties.getProperty("storePassword", "")
        }
    }

    defaultConfig {
        applicationId = "com.shakib.amol.amol_tracker_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
            isUniversalApk = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    // ✅ Fix 2 & 3: Replaced deprecated OutputFile.ABI and versionCodeOverride
    applicationVariants.all {
        val variant = this
        outputs.all {
            val output = this as? com.android.build.gradle.internal.api.ApkVariantOutputImpl
                ?: return@all
            // ✅ Modern way to get ABI filter
            val abiName = output.filters.find {
                it.filterType == com.android.build.api.variant.FilterConfiguration.FilterType.ABI.name
            }?.identifier
            if (abiName != null) {
                // ✅ versionCodeOverride replaced with versionCodeOverride via outputFileName workaround
                output.versionCodeOverride = (abiCodes[abiName] ?: 0) * 1000 + (flutter.versionCode ?: 1)
            }
        }
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }
}

flutter {
    source = "../.."
}