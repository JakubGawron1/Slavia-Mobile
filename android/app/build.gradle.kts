plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/** Katalog główny repo (folder zawierający `pubspec.yaml`). */
val repoRoot: java.io.File = rootProject.projectDir.parentFile!!

/**
 * Wersja **versionName**: tag na `HEAD` (`git describe --tags --exact-match`),
 * inaczej najwyższy tag `v*` (`git tag -l "v*" --sort=-version:refname`), na końcu `pubspec.yaml`.
 * **versionCode**: `git rev-list --count HEAD` (monotoniczny przyrost przy każdym commicie).
 * Przed buildem warto `git fetch --tags`, żeby lokalnie mieć te same tagi co GitHub.
 * Gdy Git niedostępny — wartości z `pubspec.yaml` (Flutter).
 */
fun gitStdout(vararg args: String): String? {
    return try {
        val proc =
            ProcessBuilder(listOf("git", *args))
                .directory(repoRoot)
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
        val text =
            proc.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
        proc.waitFor()
        if (proc.exitValue() != 0) null else text.trim().takeIf { it.isNotEmpty() }
    } catch (_: Exception) {
        null
    }
}

/** Tag dokładnie na `HEAD` (np. build z `git checkout v0.8.0` lub tag na commicie main). */
fun gitDescribeExactTagAtHead(): String? {
    val raw =
        gitStdout("describe", "--tags", "--exact-match", "HEAD") ?: return null
    return raw.removePrefix("v").removePrefix("V").trim().takeIf { it.isNotEmpty() }
}

/** Najwyższy tag `v*` (sortowanie wersji Git), gdy HEAD nie jest na tagu. */
fun gitLatestTagAsVersionName(): String? {
    val raw =
        gitStdout("tag", "-l", "v*", "--sort=-version:refname") ?: return null
    val first =
        raw.lineSequence().firstOrNull { it.isNotBlank() }?.trim() ?: return null
    return first.removePrefix("v").removePrefix("V").trim().takeIf { it.isNotEmpty() }
}

fun gitRevCount(): Int? = gitStdout("rev-list", "--count", "HEAD")?.toIntOrNull()

android {
    namespace = "com.jakubgawron.cksslavia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.jakubgawron.cksslavia"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        val tagVer = gitDescribeExactTagAtHead() ?: gitLatestTagAsVersionName()
        val commits = gitRevCount() ?: 0
        val pubspecCode = flutter.versionCode
        versionName = tagVer ?: flutter.versionName
        // Zawsze rośnie przy bumpie w pubspec (+N); git rev-list jako podłoga dla CI bez bumpu.
        versionCode = (commits * 1000 + pubspecCode).coerceAtLeast(pubspecCode)
    }

    signingConfigs {
        val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")?.trim().orEmpty()
        if (keystorePath.isNotEmpty() && file(keystorePath).isFile) {
            create("release") {
                storeFile = file(keystorePath)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
            // Bez ANDROID_KEYSTORE_PATH — debug keystore (patrz docs/android-signing.md).
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
