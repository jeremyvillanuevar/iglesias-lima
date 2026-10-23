import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show appFlavor;

import 'app_flavor.dart';

/// Configuración del mapa.
///
/// La clave de Google Maps vive en UN lugar por plataforma (ver
/// COMO_CONECTAR_FIREBASE_Y_MAPS.md, sección 4):
///   - Android: android/gradle.properties -> GOOGLE_MAPS_API_KEY
///     (se inyecta en el AndroidManifest; el SDK nativo la lee de ahí).
///   - Web:     web/index.html -> variable claveGoogleMaps
///     (carga el script de Maps JavaScript API).
///   - Este archivo solo decide QUÉ mapa dibujar: [googleMapsApiKey] es el
///     "interruptor". Mientras contenga 'PEGA_AQUI', la app usa OpenStreetMap.
///     Se puede sobrescribir al compilar con
///     `--dart-define=GOOGLE_MAPS_API_KEY=...`.
///
/// Además, si Google Maps falla en tiempo de ejecución (el script web no carga,
/// la clave es rechazada o el mapa nativo no se crea), [respaldoOsm] pasa a
/// true y todas las pantallas cambian solas a OpenStreetMap.
abstract final class MapsConfig {
  /// Interruptor de Google Maps (misma clave que Android y web).
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCzelNMtfQuu6oEbKFgVB053aDgiWho_rM',
  );

  /// Texto que indica que la clave todavía no se configuró.
  static const String marcadorPlaceholder = 'PEGA_AQUI';

  /// true si hay una clave real (no placeholder).
  static bool get claveConfigurada =>
      googleMapsApiKey.isNotEmpty &&
      !googleMapsApiKey.contains(marcadorPlaceholder);

  /// true = Google Maps falló en tiempo de ejecución => usar OpenStreetMap.
  /// (En las pruebas automáticas se activa en test/flutter_test_config.dart.)
  static final ValueNotifier<bool> respaldoOsm = ValueNotifier<bool>(false);

  /// true = Google Maps; false = OpenStreetMap.
  static bool get usarGoogleMaps => claveConfigurada && !respaldoOsm.value;

  /// Pasa a OpenStreetMap para el resto de la sesión.
  static void activarRespaldoOsm() {
    if (!respaldoOsm.value) respaldoOsm.value = true;
  }

  /// Plantilla de teselas de OpenStreetMap.
  static const String urlTeselasOsm =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Identificador que OpenStreetMap exige en el User-Agent: el paquete de
  /// la app que se está ejecutando (ej. pe.iglesiaslima.catolica).
  static String get userAgentPaquete =>
      AppFlavor.desdeId(appFlavor).applicationId;
}
