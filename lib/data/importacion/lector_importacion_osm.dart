import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/config/fuente_importacion_osm.dart';
import 'paquete_importacion_osm.dart';

/// Lee un archivo de importación de OpenStreetMap incluido en la app.
class LectorImportacionOsm {
  LectorImportacionOsm({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;

  Future<PaqueteImportacionOsm> leer(FuenteImportacionOsm fuente) async {
    final texto = await (_bundle ?? rootBundle)
        .loadString(fuente.rutaAsset, cache: false);
    final json = jsonDecode(texto);
    if (json is! Map) {
      throw const FormatException('Archivo de importación no válido.');
    }
    final paquete =
        PaqueteImportacionOsm.desdeJson(Map<String, dynamic>.from(json));
    if (paquete.denominacion != fuente.denominacion) {
      throw FormatException('El archivo ${fuente.rutaAsset} no es de iglesias '
          '${fuente.denominacion.label}.');
    }
    return paquete;
  }
}
