import '../../data/models/enums.dart';

/// Archivo de iglesias de OpenStreetMap incluido en la app (assets) para una
/// denominación. Es la pieza que cada app reutiliza: la App 1 trae el de
/// iglesias católicas de Lima; las Apps 2 a 5 solo tienen que agregar su
/// archivo aquí (en [todas]) y declararlo en pubspec.yaml.
class FuenteImportacionOsm {
  const FuenteImportacionOsm({
    required this.denominacion,
    required this.rutaAsset,
    required this.area,
  });

  final Denominacion denominacion;

  /// Ruta del JSON dentro de los assets (ver assets/importacion/).
  final String rutaAsset;

  /// Zona que cubre el archivo (texto para la pantalla).
  final String area;

  /// Iglesias católicas de Lima Metropolitana y Callao (App 1).
  static const FuenteImportacionOsm catolicasLima = FuenteImportacionOsm(
    denominacion: Denominacion.catolica,
    rutaAsset: 'assets/importacion/iglesias_catolicas_lima_osm.json',
    area: 'Lima Metropolitana y Callao',
  );

  /// Iglesias evangélicas de Lima Metropolitana y Callao (App 2).
  static const FuenteImportacionOsm evangelicasLima = FuenteImportacionOsm(
    denominacion: Denominacion.evangelica,
    rutaAsset: 'assets/importacion/iglesias_evangelicas_lima_osm.json',
    area: 'Lima Metropolitana y Callao',
  );

  /// Iglesias adventistas (solo datos; aún no hay app propia).
  static const FuenteImportacionOsm adventistasLima = FuenteImportacionOsm(
    denominacion: Denominacion.adventista,
    rutaAsset: 'assets/importacion/iglesias_adventistas_lima_osm.json',
    area: 'Lima Metropolitana y Callao',
  );

  /// Todos los archivos disponibles hoy.
  static const List<FuenteImportacionOsm> todas = [
    catolicasLima,
    evangelicasLima,
    adventistasLima,
  ];

  /// Archivos que puede importar una app que muestra [denominaciones].
  static List<FuenteImportacionOsm> para(List<Denominacion> denominaciones) =>
      todas.where((f) => denominaciones.contains(f.denominacion)).toList();
}
