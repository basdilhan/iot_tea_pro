plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // Make sure this line is here
}

// Read the local properties file
val localProperties = java.util.Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { stream ->
        localProperties.load(stream)
    }
}
val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.iot_tea"
    compileSdk = 34 // Use 34 or whatever your Flutter SDK recommends

    defaultConfig {
        // ...
        applicationId = "com.example.iot_tea"
        
        // --- THIS IS THE SECTION TO FIX ---
        // Use = and ( ) for Kotlin Script
        minSdkVersion(20) 
        targetSdkVersion(33)
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        multiDexEnabled = true // Use =
        // --- END OF FIX ---
    }

    signingConfigs {
        create("debug") {
            // ... your debug signing config
        }
    }

    buildTypes {
        getByName("release") {
            // ... your release settings
        }
    }
}

dependencies {
    // --- THIS IS THE OTHER SECTION TO FIX ---
    // Use ("...") for Kotlin Script
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version")
    implementation("androidx.multidex:multidex:2.0.1")
    // --- END OF FIX ---
}