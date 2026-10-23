import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

import 'estado_google_maps.dart';

export 'estado_google_maps.dart';

/// Web: lee las banderas que deja web/index.html
/// (`googleMapsListo`, `googleMapsFallo`) y se registra para enterarse
/// cuando cambian (`alCambiarGoogleMaps`).
abstract final class DisponibilidadGoogleMaps {
  static const Duration _tiempoMaximo = Duration(seconds: 12);

  static final ValueNotifier<EstadoGoogleMaps> estado = _crear();

  static ValueNotifier<EstadoGoogleMaps> _crear() {
    final notifier = ValueNotifier<EstadoGoogleMaps>(_leer());
    if (notifier.value == EstadoGoogleMaps.cargando) {
      void actualizar() => notifier.value = _leer();

      globalContext['alCambiarGoogleMaps'] = actualizar.toJS;
      Timer(_tiempoMaximo, () {
        if (notifier.value == EstadoGoogleMaps.cargando) {
          notifier.value = EstadoGoogleMaps.fallo;
        }
      });
    } else {
      // Aunque ya esté listo, la clave puede ser rechazada después
      // (gm_authFailure): seguimos escuchando.
      globalContext['alCambiarGoogleMaps'] = (() {
        notifier.value = _leer();
      }).toJS;
    }
    return notifier;
  }

  static EstadoGoogleMaps _leer() {
    if (_bandera('googleMapsFallo')) return EstadoGoogleMaps.fallo;
    if (_bandera('googleMapsListo')) return EstadoGoogleMaps.listo;
    return EstadoGoogleMaps.cargando;
  }

  static bool _bandera(String nombre) {
    final v = globalContext[nombre];
    return v != null && v.isA<JSBoolean>() && (v as JSBoolean).toDart;
  }

  /// true si web/index.html cargó la librería js-markerclusterer
  /// (sin ella, google_maps_flutter_web falla al agrupar pines).
  static bool get agrupacionDisponible =>
      globalContext['markerClusterer'] != null;
}
