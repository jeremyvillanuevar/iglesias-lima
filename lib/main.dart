import 'package:flutter/services.dart' show appFlavor;

import 'core/config/app_flavor.dart';
import 'core/di/arranque_app.dart';

/// Punto de entrada por defecto.
///
/// - `flutter run` (sin flavor) y la versión web => [AppFlavor.porDefecto]
///   (hoy la App 1, Católica).
/// - `flutter run --flavor catolica` (sin -t) también funciona: se lee el
///   flavor que Flutter pasa en [appFlavor].
///
/// Cada app tiene además su propio punto de entrada (lib/main_<flavor>.dart).
Future<void> main() => arrancarApp(AppFlavor.desdeId(appFlavor));
