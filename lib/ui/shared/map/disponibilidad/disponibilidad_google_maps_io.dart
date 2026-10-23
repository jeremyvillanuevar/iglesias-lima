import 'package:flutter/foundation.dart';

import 'estado_google_maps.dart';

export 'estado_google_maps.dart';

/// Android: Google Maps se inicializa de forma nativa, siempre "listo".
/// Si el mapa no llega a crearse, MapaGoogle activa el respaldo OSM.
abstract final class DisponibilidadGoogleMaps {
  static final ValueNotifier<EstadoGoogleMaps> estado =
      ValueNotifier<EstadoGoogleMaps>(EstadoGoogleMaps.listo);

  /// La agrupación de pines nativa siempre está disponible.
  static bool get agrupacionDisponible => true;
}
