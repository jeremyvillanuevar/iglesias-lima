import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;

import '../models/enums.dart';
import '../models/user_model.dart';
import 'permiso_denegado_exception.dart';

/// Quién puede moderar (aprobar/rechazar) y quién puede borrar físicamente.
/// Lo usan los ViewModels (para mostrar u ocultar botones) y las
/// implementaciones Demo (para comportarse igual que firestore.rules).
abstract final class PermisosModeracion {
  /// Puede abrir la pantalla de Moderación: Admin General o Pastor/Padre.
  static bool puedeAbrirModeracion(UserModel? u) =>
      u != null &&
      u.estadoCuenta == EstadoCuenta.activo &&
      (u.rolGlobal == RolGlobal.adminGeneral ||
          u.rolGlobal == RolGlobal.pastorPadre);

  static bool esAdmin(UserModel? u) =>
      u != null &&
      u.estadoCuenta == EstadoCuenta.activo &&
      u.rolGlobal == RolGlobal.adminGeneral;

  /// Aprobar/Rechazar: el Admin General siempre; un aprobador (líder de la
  /// iglesia) solo si NO es quien lo creó.
  static bool puedeModerar({
    required UserModel? usuario,
    required DocumentReference? miRef,
    required DocumentReference creadoPor,
    required bool soyAprobador,
  }) {
    if (esAdmin(usuario)) return true;
    if (usuario == null || miRef == null) return false;
    if (usuario.estadoCuenta != EstadoCuenta.activo) return false;
    return soyAprobador && creadoPor.path != miRef.path;
  }

  /// Lanza [PermisoDenegadoException] si no se cumple [puedeModerar].
  static void exigirModerar({
    required UserModel? usuario,
    required DocumentReference? miRef,
    required DocumentReference creadoPor,
    required bool soyAprobador,
  }) {
    if (puedeModerar(
      usuario: usuario,
      miRef: miRef,
      creadoPor: creadoPor,
      soyAprobador: soyAprobador,
    )) {
      return;
    }
    if (miRef != null && creadoPor.path == miRef.path && !esAdmin(usuario)) {
      throw const PermisoDenegadoException(
          'No puedes aprobar ni rechazar algo que tú mismo creaste.');
    }
    throw const PermisoDenegadoException(
        'Solo el aprobador a cargo de la iglesia o el Administrador General '
        'pueden aprobar o rechazar.');
  }

  /// Acciones reservadas al Administrador General (aprobar reclamos,
  /// importar de OpenStreetMap…). [accion] completa la frase del error.
  static void exigirAdminPara(UserModel? u, String accion) {
    if (!esAdmin(u)) {
      throw PermisoDenegadoException(
          'Solo el Administrador General puede $accion.');
    }
  }

  /// Borrado físico (Hard Delete): solo el Administrador General (RF-2.5).
  static void exigirAdmin(UserModel? u) {
    if (!esAdmin(u)) {
      throw const PermisoDenegadoException(
          'Solo el Administrador General puede borrar definitivamente.');
    }
  }
}
