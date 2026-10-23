/// Resumen de una importación de OpenStreetMap.
class ResultadoImportacion {
  const ResultadoImportacion({
    required this.total,
    required this.creadas,
    required this.yaExistian,
    required this.atribucion,
    this.porVerificar = 0,
  });

  /// Iglesias que trae el archivo.
  final int total;

  /// Iglesias nuevas que se guardaron ahora.
  final int creadas;

  /// Ya estaban importadas (no se tocan: importar dos veces no duplica).
  final int yaExistian;

  /// Atribución de OpenStreetMap (licencia ODbL).
  final String atribucion;

  /// De las creadas, cuántas quedaron "Por verificar".
  final int porVerificar;

  ResultadoImportacion sumar(ResultadoImportacion otro) => ResultadoImportacion(
        total: total + otro.total,
        creadas: creadas + otro.creadas,
        yaExistian: yaExistian + otro.yaExistian,
        porVerificar: porVerificar + otro.porVerificar,
        atribucion: atribucion == otro.atribucion
            ? atribucion
            : '$atribucion\n${otro.atribucion}',
      );
}
