plugins {
    id("com.android.application")
    // Firebase: procesa google-services.json de cada flavor
    // (android/app/src/<flavor>/google-services.json).
    id("com.google.gms.google-services")
    // El plugin de Flutter debe aplicarse después de los plugins de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

import com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy

// =============================================================================
// CLAVE DE GOOGLE MAPS PARA ANDROID
// NO se escribe aquí: se lee de la propiedad GOOGLE_MAPS_API_KEY de
// android/gradle.properties (o de `-P GOOGLE_MAPS_API_KEY=...` al compilar) y
// se inyecta en AndroidManifest.xml mediante manifestPlaceholders.
// Recuerda poner la MISMA clave en lib/core/config/maps_config.dart y en
// web/index.html para que la app deje de usar OpenStreetMap.
// =============================================================================
val googleMapsApiKey: String =
    (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)
        ?: "PEGA_AQUI_TU_GOOGLE_MAPS_API_KEY"

// =============================================================================
// FIREBASE (google-services.json por flavor)
// Cada app trae su propio archivo en android/app/src/<flavor>/google-services.json
// (hoy existen los de catolica y evangelica). Los flavors que aún no lo tienen compilan
// igual (con un aviso) y arrancan en Modo Demo, porque su App ID en
// lib/firebase_options.dart sigue siendo PEGA_AQUI.
// =============================================================================
googleServices {
    missingGoogleServicesStrategy = MissingGoogleServicesStrategy.WARN
}

android {
    // Paquete del código Kotlin (MainActivity). No cambia entre flavors.
    namespace = "pe.iglesiaslima.iglesias_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identificador base; cada flavor (abajo) define el suyo propio.
        applicationId = "pe.iglesiaslima.catolica"
        // Firebase Auth y Google Maps necesitan Android 7.0 (API 24) o superior.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
        manifestPlaceholders["appLabel"] = "Iglesias Católicas Lima"
    }

    // =========================================================================
    // FLAVORS: una app por denominación, todas con el MISMO backend Firebase.
    // El id del flavor debe coincidir con AppFlavor.id (lib/core/config/
    // app_flavor.dart) y con su punto de entrada lib/main_<id>.dart.
    //   flutter build apk --flavor catolica -t lib/main_catolica.dart
    // Cada applicationId debe registrarse como app Android en Firebase
    // (ver COMO_CONECTAR_FIREBASE_Y_MAPS.md).
    // La App 6 (Gamificación) es un proyecto aparte y no figura aquí.
    // =========================================================================
    flavorDimensions += "app"
    productFlavors {
        create("catolica") {          // App 1 (la que se entrega hoy)
            dimension = "app"
            applicationId = "pe.iglesiaslima.catolica"
            manifestPlaceholders["appLabel"] = "Iglesias Católicas Lima"
        }
        create("evangelica") {        // App 2
            dimension = "app"
            applicationId = "pe.iglesiaslima.evangelica"
            manifestPlaceholders["appLabel"] = "Iglesias Evangélicas Lima"
        }
        create("jehova") {            // App 3 (Gradle prohíbe nombres que empiecen con "test")
            dimension = "app"
            applicationId = "pe.iglesiaslima.testigos"
            manifestPlaceholders["appLabel"] = "Testigos de Jehová Lima"
        }
        create("ijsud") {             // App 4
            dimension = "app"
            applicationId = "pe.iglesiaslima.ijsud"
            manifestPlaceholders["appLabel"] = "IJSUD Lima"
        }
        create("global") {            // App 5: todas las denominaciones
            dimension = "app"
            applicationId = "pe.iglesiaslima.global"
            manifestPlaceholders["appLabel"] = "Visión Global Cristiana"
        }
    }

    signingConfigs {
        // Clave de DEPURACIÓN incluida en el proyecto (android/app/debug.keystore)
        // para que el APK tenga SIEMPRE la misma firma y la misma huella SHA-1,
        // sin importar en qué computadora se compile (necesario para el login
        // con Google). No es una clave para publicar en Google Play.
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // MVP: el APK de release se firma con la clave de depuración para que
            // se pueda instalar directamente en el teléfono. Antes de publicar en
            // Google Play, crea tu propia clave (keystore) y cámbiala aquí.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
