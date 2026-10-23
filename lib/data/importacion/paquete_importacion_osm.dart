import '../models/enums.dart';
import 'iglesia_osm.dart';

/// Contenido de un archivo de importación de OpenStreetMap: las iglesias y
/// la atribución que exige la licencia ODbL.
class PaqueteImportacionOsm {
  const PaqueteImportacionOsm({
    required this.denominacion,
    required this.atribucion,
    required this.licencia,
    required this.area,
    required this.iglesias,
    this.fechaDatos,
  });

  final Denominacion denominacion;

  /// '© Colaboradores de OpenStreetMap …' (se muestra al importar).
  final String atribucion;
  final String licencia;
  final String area;
  final List<IglesiaOsm> iglesias;

  /// Fecha de los datos de OSM con que se generó el archivo.
  final String? fechaDatos;

  factory PaqueteImportacionOsm.desdeJson(Map<String, dynamic> j) {
    final lista = j['iglesias'];
    if (lista is! List) {
      throw const FormatException('El archivo no trae la lista "iglesias".');
    }
    final iglesias = <String, IglesiaOsm>{};
    for (final e in lista) {
      final i = IglesiaOsm.desdeJson(Map<String, dynamic>.from(e as Map));
      iglesias.putIfAbsent(i.osmId, () => i); // Sin repetidos.
    }
    return PaqueteImportacionOsm(
      denominacion: Denominacion.fromValue(j['denominacion']),
      atribucion:
          j['atribucion'] as String? ?? '© Colaboradores de OpenStreetMap',
      licencia: j['licencia'] as String? ?? 'ODbL 1.0',
      area: j['area'] as String? ?? '',
      fechaDatos: j['fecha_datos_osm'] as String?,
      iglesias: iglesias.values.toList(),
    );
  }
}
