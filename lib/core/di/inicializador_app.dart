import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/app_flavor.dart';
import 'dependencias.dart';

/// Decide al arrancar si la app usa Firebase real o el Modo Demo.
///
/// Nunca lanza errores: si algo falla, la app sigue en Modo Demo
/// en lugar de cerrarse o quedarse en blanco.
abstract final class InicializadorApp {
  static const Duration _tiempoMaximo = Duration(seconds: 12);

  static Future<Dependencias> inicializar([
    AppFlavor flavor = AppFlavor.porDefecto,
  ]) async {
    if (tienePlaceholders(flavor)) {
      return Dependencias.demo(
        flavor: flavor,
        motivo: 'firebase_options.dart todavía tiene valores PEGA_AQUI '
            'para ${flavor.nombreApp}.',
      );
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.paraFlavor(flavor),
        ).timeout(_tiempoMaximo);
      }
      return Dependencias.firebase(flavor);
    } catch (e, st) {
      debugPrint('No se pudo iniciar Firebase, se usa el Modo Demo: $e\n$st');
      return Dependencias.demo(
        flavor: flavor,
        motivo: 'Firebase.initializeApp falló: $e',
      );
    }
  }

  /// true si lib/firebase_options.dart todavía tiene textos 'PEGA_AQUI'
  /// para [flavor] (o si la plataforma no está configurada).
  static bool tienePlaceholders([AppFlavor flavor = AppFlavor.porDefecto]) {
    try {
      final o = DefaultFirebaseOptions.paraFlavor(flavor);
      return [o.apiKey, o.appId, o.projectId, o.messagingSenderId]
          .any((v) => v.isEmpty || v.contains('PEGA_AQUI'));
    } catch (_) {
      return true;
    }
  }
}
