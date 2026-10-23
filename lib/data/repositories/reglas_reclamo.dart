import '../models/enums.dart';
import '../models/iglesia_model.dart';
import '../models/solicitud_reclamo_model.dart';

/// Reglas de los reclamos de iglesias, compartidas por Firebase y el Modo
/// Demo (firestore.rules vuelve a comprobarlas en el servidor).
abstract final class ReglasReclamo {
  static const int maxCargo = 80;
  static const int maxMensaje = 500;

  /// Lanza [ArgumentError] si no se puede enviar la solicitud.
  static void validarNueva({
    required IglesiaModel iglesia,
    required String cargo,
    String? mensaje,
    SolicitudReclamoModel? existente,
  }) {
    if (!iglesia.esPublica) {
      throw ArgumentError('Solo se pueden reclamar iglesias publicadas.');
    }
    if (iglesia.esAdministrada) {
      throw ArgumentError('Esta iglesia ya tiene un administrador.');
    }
    final c = cargo.trim();
    if (c.isEmpty) {
      throw ArgumentError('Indica tu cargo en la iglesia.');
    }
    if (c.length > maxCargo) {
      throw ArgumentError('El cargo admite hasta $maxCargo caracteres.');
    }
    if ((mensaje?.trim().length ?? 0) > maxMensaje) {
      throw ArgumentError('El mensaje admite hasta $maxMensaje caracteres.');
    }
    if (existente != null) {
      switch (existente.estado) {
        case EstadoAprobacion.pendiente:
          throw ArgumentError(
              'Ya enviaste una solicitud para esta iglesia: está en revisión.');
        case EstadoAprobacion.aprobado:
          throw ArgumentError(
              'Tu solicitud para esta iglesia ya fue aprobada.');
        case EstadoAprobacion.rechazado:
          break; // Se puede volver a enviar.
      }
    }
  }

  /// Rol que recibe el solicitante al aprobarse su reclamo: pasa a
  /// Pastor/Padre (para moderar lo de su iglesia) salvo que ya tenga un rol
  /// igual o mayor.
  static RolGlobal rolTrasAprobar(RolGlobal actual) {
    switch (actual) {
      case RolGlobal.usuario:
      case RolGlobal.coordinador:
        return RolGlobal.pastorPadre;
      case RolGlobal.pastorPadre:
      case RolGlobal.adminGeneral:
        return actual;
    }
  }

  /// Lanza [ArgumentError] si la solicitud ya no está Pendiente.
  static void exigirPendiente(SolicitudReclamoModel? s) {
    if (s == null) throw ArgumentError('La solicitud ya no existe.');
    if (!s.estaPendiente) {
      throw ArgumentError('Esta solicitud ya fue resuelta.');
    }
  }
}
