plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.numforlife.com"
    compileSdk = 36

    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "app.numforlife.com"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 121
        versionName = "1.1.0"
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file("app.numforlife.com.keystore")
            storePassword = "123456"
            keyAlias = "app.numforlife.com"
            keyPassword = "123456"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    // ✅ Java 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.webkit:webkit:1.8.0")
    implementation("androidx.multidex:multidex:2.0.1")
}
