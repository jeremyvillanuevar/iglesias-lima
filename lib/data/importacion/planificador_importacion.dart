import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;

import '../../core/config/fuente_importacion_osm.dart';
import '../models/iglesia_model.dart';
import 'paquete_importacion_osm.dart';

/// Convierte un paquete de OpenStreetMap en las iglesias que faltan crear,
/// separadas en lotes. Lo usan Firebase y el Modo Demo, así ambos importan
/// igual y de forma idempotente.
class PlanificadorImportacion {
  const PlanificadorImportacion({this.tamanoLote = 400});

  /// Escrituras por lote (Firestore admite hasta 500).
  final int tamanoLote;

  /// País y localidad que reciben las iglesias importadas. Callao comparte
  /// la localidad "Lima" para que salgan en el mismo mapa.
  static const String pais = 'Perú';
  static const String localidad = 'Lima';

  /// Iglesias del [paquete] cuyo id aún no está en [idsExistentes].
  List<IglesiaModel> faltantes({
    required FuenteImportacionOsm fuente,
    required PaqueteImportacionOsm paquete,
    required Set<String> idsExistentes,
    required DocumentReference creadoPor,
  }) {
    return [
      for (final o in paquete.iglesias)
        if (!idsExistentes.contains(o.idDocumento))
          IglesiaModel.desdeOsm(
            osmId: o.osmId,
            nombre: o.nombre,
            denominacion: fuente.denominacion,
            latitud: o.latitud,
            longitud: o.longitud,
            direccionTexto: o.direccionTexto,
            pais: pais,
            localidad: localidad,
            creadoPor: creadoPor,
            verificacionDenominacion: o.verificacion,
            criterioOsm: o.criterio,
          ),
    ];
  }

  /// Parte [lista] en lotes de [tamanoLote].
  List<List<T>> enLotes<T>(List<T> lista) {
    return [
      for (var i = 0; i < lista.length; i += tamanoLote)
        lista.sublist(
            i, i + tamanoLote > lista.length ? lista.length : i + tamanoLote),
    ];
  }
}
