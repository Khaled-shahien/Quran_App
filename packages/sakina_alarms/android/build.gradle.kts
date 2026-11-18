group = "app.sakina.alarms"
version = "1.0"

// Versions come from the host app's settings.gradle.kts plugin block.
plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "app.sakina.alarms"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }
}
