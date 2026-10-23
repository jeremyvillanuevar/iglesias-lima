import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../config/app_flavor.dart';
import 'inicializador_app.dart';

/// Arranque común de las 5 apps de directorio.
///
/// 1. Prepara fechas en español.
/// 2. Intenta conectar Firebase con la app Android/web de [flavor]; si no está
///    configurado o falla, entra en Modo Demo (datos de ejemplo en memoria).
///    La app nunca queda en blanco.
Future<void> arrancarApp(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15+ dibuja siempre de borde a borde; lo activamos en todas las
  // versiones y cada pantalla respeta las barras del sistema
  // (ver lib/ui/shared/layout/margenes_sistema.dart).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: true,
    statusBarColor: Colors.transparent,
  ));
  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es');

  final dependencias = await InicializadorApp.inicializar(flavor);
  runApp(IglesiasApp(dependencias: dependencias));
}
