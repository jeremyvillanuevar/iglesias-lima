// ============================================================================
// CONFIGURACIÓN DE FIREBASE  (único archivo con claves de Firebase)
// ----------------------------------------------------------------------------
// Las 5 apps (flavors) comparten UN solo proyecto de Firebase y las mismas
// cuentas. Lo único que cambia por app es el "App ID" de Android, porque en
// Firebase cada paquete (pe.iglesiaslima.catolica, ...) se registra como una
// app Android distinta dentro del MISMO proyecto.
//
// Proyecto real: iglesias-lima (Firestore "(default)" en southamerica-west1).
// Hoy la App 1 (Católica) y la App 2 (Evangélica, solo Android) tienen sus
// App ID reales => usan Firebase.
// Las apps cuyo App ID todavía dice 'PEGA_AQUI_...' arrancan en MODO DEMO
// (datos de ejemplo en memoria, sin Firebase) hasta que se registren.
//
// Dónde copiar cada valor: Firebase Console > Configuración del proyecto >
// Tus apps. Ver COMO_CONECTAR_FIREBASE_Y_MAPS.md
// ============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/app_flavor.dart';

class DefaultFirebaseOptions {
  // ------------------------------------------- PROYECTO (compartido por todas) --
  static const String _projectId = 'iglesias-lima';
  static const String _messagingSenderId = '229289277006';
  static const String _storageBucket = 'iglesias-lima.firebasestorage.app';
  static const String _authDomain = 'iglesias-lima.firebaseapp.com';

  // ---------------------------------------------------------------- ANDROID --
  /// "current_key" del google-services.json (es la misma para todas las apps
  /// Android del proyecto).
  static const String _apiKeyAndroid =
      'AIzaSyAxMBkpsYRk1tbhsbBcX5aNe6Ih8OlnrBQ';

  /// "mobilesdk_app_id" de cada app Android registrada (uno por flavor).
  static const Map<AppFlavor, String> _appIdAndroid = {
    AppFlavor.catolica: '1:229289277006:android:c263b9e76af88e5227751f',
    AppFlavor.evangelica: '1:229289277006:android:21d73df3ca75b30727751f',
    AppFlavor.jehova: 'PEGA_AQUI_TU_APP_ID_ANDROID_JEHOVA',
    AppFlavor.ijsud: 'PEGA_AQUI_TU_APP_ID_ANDROID_IJSUD',
    AppFlavor.global: 'PEGA_AQUI_TU_APP_ID_ANDROID_GLOBAL',
  };

  // -------------------------------------------------------------------- WEB --
  static const String _apiKeyWeb = 'AIzaSyD3EKN4q1r3vr4h820D9FiOo0sMUuWUROQ';

  /// App ID de la app web registrada para cada flavor (puede ser la misma
  /// para todas si solo publicas una versión web).
  static const Map<AppFlavor, String> _appIdWeb = {
    AppFlavor.catolica: '1:229289277006:web:a0e127c754b453d927751f',
    AppFlavor.evangelica: 'PEGA_AQUI_TU_APP_ID_WEB_EVANGELICA',
    AppFlavor.jehova: 'PEGA_AQUI_TU_APP_ID_WEB_JEHOVA',
    AppFlavor.ijsud: 'PEGA_AQUI_TU_APP_ID_WEB_IJSUD',
    AppFlavor.global: 'PEGA_AQUI_TU_APP_ID_WEB_GLOBAL',
  };

  // ------------------------------------------------------------------------
  // No necesitas tocar nada de aquí para abajo.
  // ------------------------------------------------------------------------

  static FirebaseOptions androidDe(AppFlavor flavor) => FirebaseOptions(
        apiKey: _apiKeyAndroid,
        appId: _appIdAndroid[flavor]!,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions webDe(AppFlavor flavor) => FirebaseOptions(
        apiKey: _apiKeyWeb,
        appId: _appIdWeb[flavor]!,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
      );

  /// Opciones de la plataforma actual (Android o web) para [flavor].
  static FirebaseOptions paraFlavor(AppFlavor flavor) {
    if (kIsWeb) return webDe(flavor);
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidDe(flavor);
      default:
        throw UnsupportedError(
          'Esta app solo está configurada para Android y web.',
        );
    }
  }

  /// Compatibilidad con el nombre que genera `flutterfire configure`
  /// (usa la app por defecto: App 1).
  static FirebaseOptions get currentPlatform =>
      paraFlavor(AppFlavor.porDefecto);
}
