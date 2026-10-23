import '../models/enums.dart';

/// Datos comunes de un evento antes de guardarlo (lo que llena el formulario).
/// Las fechas concretas vienen aparte, como lista de ocurrencias.
class DatosNuevoEvento {
  const DatosNuevoEvento({
    required this.tipoActividad,
    required this.titulo,
    required this.categoria,
    this.descripcion,
    this.idIglesia,
    this.idMinisterio,
    this.esVirtual = false,
    this.linkVirtual,
    this.imagenUrl,
    this.duracion,
  });

  final TipoActividad tipoActividad;
  final String titulo;
  final String categoria;
  final String? descripcion;
  final String? idIglesia;
  final String? idMinisterio;
  final bool esVirtual;
  final String? linkVirtual;
  final String? imagenUrl;

  /// Si se indica, `fecha_hora_fin` = inicio + duración.
  final Duration? duracion;
}
