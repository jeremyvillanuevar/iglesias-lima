import 'dart:async';

import 'package:iglesias_app/core/config/maps_config.dart';

/// Se ejecuta antes de cada archivo de pruebas.
///
/// En las pruebas no existe el mapa nativo de Google, así que se activa el
/// mismo respaldo automático que usa la app cuando Google Maps falla:
/// OpenStreetMap.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  MapsConfig.activarRespaldoOsm();
  await testMain();
}
