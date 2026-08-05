import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.huiqin.eternity"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.huiqin.eternity"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        ndk {
            abiFilters.add("arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        jniLibs {
            excludes += setOf(
                "lib/armeabi-v7a/**",
                "lib/x86_64/**",
                "lib/x86/**"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Remove storage permissions from merged manifest for Google Play compliance.
// Runs after the manifest merge task, before AAB/APK signing.
afterEvaluate {
    tasks.matching {
        it.name.contains("process", ignoreCase = true)
                && it.name.contains("Manifest", ignoreCase = true)
                && it.name.contains("Release", ignoreCase = true)
    }.configureEach {
        doLast {
            val manifestFile = layout.buildDirectory
                .file("intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml")
                .get().asFile

            logger.lifecycle("[WorkBuddy] Checking merged manifest: $manifestFile")
            if (!manifestFile.exists()) {
                logger.lifecycle("[WorkBuddy] Manifest not found, skipping")
                return@doLast
            }

            var text = manifestFile.readText()
            val permissionsToRemove = listOf(
                "android.permission.READ_MEDIA_IMAGES",
                "android.permission.READ_MEDIA_VIDEO",
                "android.permission.READ_MEDIA_AUDIO",
                "android.permission.READ_EXTERNAL_STORAGE",
                "android.permission.WRITE_EXTERNAL_STORAGE",
                "android.permission.MANAGE_EXTERNAL_STORAGE"
            )

            var removed = 0
            for (perm in permissionsToRemove) {
                val pattern = Regex(
                    """<uses-permission\s+([^>]*\n?)*android:name=\"$perm\"(\n?[^>]*)*/>""",
                    RegexOption.DOT_MATCHES_ALL
                )
                val before = text.length
                text = pattern.replace(text, "")
                if (text.length < before) {
                    removed++
                    logger.lifecycle("[WorkBuddy] Removed permission: $perm")
                }
            }

            if (removed > 0) {
                manifestFile.writeText(text)
                logger.lifecycle("[WorkBuddy] Removed $removed storage permission(s) from merged manifest")
            } else {
                logger.lifecycle("[WorkBuddy] No storage permissions to remove")
            }
        }
    }
}
