import '../models/enums.dart';
import '../recurrencia/ocurrencia_evento.dart';
import 'datos_nuevo_evento.dart';

/// Validaciones de negocio compartidas por las implementaciones Firebase y
/// Demo, para que ambas se comporten igual (y igual que firestore.rules).
abstract final class ReglasValidacion {
  static void validarIglesia({
    required String nombre,
    required TipoUbicacion tipo,
    required bool tieneUbicacion,
    String? linkVirtual,
    required String pais,
    required String localidad,
  }) {
    if (nombre.trim().isEmpty) {
      throw ArgumentError('El nombre de la iglesia es obligatorio.');
    }
    if (tipo == TipoUbicacion.fisica && !tieneUbicacion) {
      throw ArgumentError('Marca la ubicación de la iglesia en el mapa.');
    }
    if (tipo == TipoUbicacion.virtual &&
        (linkVirtual == null || linkVirtual.trim().isEmpty)) {
      throw ArgumentError('Una iglesia virtual necesita un enlace web.');
    }
    if (pais.trim().isEmpty || localidad.trim().isEmpty) {
      throw ArgumentError('Indica el país y la localidad.');
    }
  }

  /// RF-3.2 / RF-3.3: matriz, ubicación propia (con país/localidad) o virtual.
  static void validarMinisterio({
    required String nombre,
    required TipoUbicacionMinisterio tipoUbicacion,
    String? idIglesia,
    required bool tieneUbicacion,
    String? linkVirtual,
    String? pais,
    String? localidad,
  }) {
    if (nombre.trim().isEmpty) {
      throw ArgumentError('El nombre del ministerio es obligatorio.');
    }
    switch (tipoUbicacion) {
      case TipoUbicacionMinisterio.iglesia:
        if (idIglesia == null) {
          throw ArgumentError('Elige la iglesia matriz del ministerio.');
        }
      case TipoUbicacionMinisterio.fisica:
        if (!tieneUbicacion) {
          throw ArgumentError('Marca la ubicación del ministerio en el mapa.');
        }
        if ((pais ?? '').trim().isEmpty || (localidad ?? '').trim().isEmpty) {
          throw ArgumentError('Indica el país y la localidad del ministerio.');
        }
      case TipoUbicacionMinisterio.virtual:
        if (linkVirtual == null || linkVirtual.trim().isEmpty) {
          throw ArgumentError('Un ministerio virtual necesita un enlace web.');
        }
    }
  }

  static void validarEvento(
      DatosNuevoEvento d, List<OcurrenciaEvento> ocurrencias) {
    if (d.titulo.trim().isEmpty) {
      throw ArgumentError('El título es obligatorio.');
    }
    if (d.categoria.trim().isEmpty) {
      throw ArgumentError('Elige una categoría.');
    }
    if (d.idIglesia == null && d.idMinisterio == null) {
      throw ArgumentError(
          'El evento debe pertenecer a una iglesia o a un ministerio.');
    }
    if (d.duracion != null && d.duracion! <= Duration.zero) {
      throw ArgumentError('La hora de fin debe ser posterior a la de inicio.');
    }
    if (d.esVirtual &&
        (d.linkVirtual == null || d.linkVirtual!.trim().isEmpty)) {
      throw ArgumentError('Un evento virtual necesita un enlace (URL).');
    }
    if (ocurrencias.isEmpty) {
      throw ArgumentError('No hay ninguna fecha para crear.');
    }
  }

  static String? limpio(String? texto) {
    final t = texto?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
