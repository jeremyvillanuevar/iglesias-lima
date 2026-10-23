import '../models/enums.dart';
import '../models/iglesia_model.dart';

/// Un lugar de culto tal como viene en el archivo de OpenStreetMap.
class IglesiaOsm {
  const IglesiaOsm({
    required this.osmId,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.direccion,
    this.distrito,
    this.verificacion = VerificacionDenominacion.porVerificar,
    this.criterio,
  });

  /// 'node/123', 'way/456' o 'relation/789'.
  final String osmId;
  final String nombre;
  final double latitud;
  final double longitud;
  final String? direccion;
  final String? distrito;

  /// 'Confirmada_OSM' (etiqueta de OSM) o 'Por_Verificar' (por el nombre).
  /// Si el archivo no lo dice, se asume Por_Verificar.
  final VerificacionDenominacion verificacion;

  /// Por qué entró al archivo (`criterio_osm`); null en archivos antiguos.
  final CriterioOsm? criterio;

  /// Id del documento en Firestore: 'osm_way_456' (fijo = sin duplicados).
  String get idDocumento => IglesiaModel.idDesdeOsm(osmId);

  /// "Dirección – Distrito" (o lo que haya).
  String? get direccionTexto {
    final partes = [
      if (direccion != null && direccion!.trim().isNotEmpty) direccion!.trim(),
      if (distrito != null && distrito!.trim().isNotEmpty) distrito!.trim(),
    ];
    return partes.isEmpty ? null : partes.join(' – ');
  }

  factory IglesiaOsm.desdeJson(Map<String, dynamic> j) {
    final osmId = j['osm_id'];
    final nombre = j['nombre'];
    final lat = j['lat'];
    final lng = j['lng'];
    if (osmId is! String || nombre is! String || lat is! num || lng is! num) {
      throw FormatException('Registro de OpenStreetMap incompleto: $j');
    }
    return IglesiaOsm(
      osmId: osmId,
      nombre: nombre,
      latitud: lat.toDouble(),
      longitud: lng.toDouble(),
      direccion: j['direccion'] as String?,
      distrito: j['distrito'] as String?,
      verificacion:
          VerificacionDenominacion.fromValue(j['verificacion_denominacion']),
      criterio: CriterioOsm.fromValueOrNull(j['criterio_osm']),
    );
  }
}
