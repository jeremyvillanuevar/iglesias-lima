import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../services/iglesia_service.dart';
import '../auth_repository.dart';
import '../permiso_denegado_exception.dart';
import '../permisos_moderacion.dart';

/// Piezas comunes de la moderación con Firestore (iglesias, ministerios y
/// eventos). Las consultas respetan firestore.rules: el Admin General lee
/// todos los Pendientes; un Pastor/Padre consulta por cada iglesia que lidera
/// (filtro de igualdad por `iglesia_ref`, que las reglas pueden comprobar).
abstract final class ModeracionFirebase {
  static Stream<List<T>> pendientes<T>({
    required AuthRepository auth,
    required IglesiaService iglesias,
    required Stream<List<T>> Function() todos,
    required Stream<List<T>> Function(DocumentReference iglesiaRef) porIglesia,
  }) {
    return auth.observarPerfilActual().switchMap((perfil) {
      if (!PermisosModeracion.puedeAbrirModeracion(perfil)) {
        return Stream<List<T>>.value(<T>[]);
      }
      if (PermisosModeracion.esAdmin(perfil)) return todos();
      final miRef = auth.refUsuarioActual;
      if (miRef == null) return Stream<List<T>>.value(<T>[]);
      return iglesias.streamDeLider(miRef).switchMap((lideradas) {
        if (lideradas.isEmpty) return Stream<List<T>>.value(<T>[]);
        return Rx.combineLatestList<List<T>>([
          for (final i in lideradas) porIglesia(iglesias.refDe(i.idIglesia)),
        ]).map((listas) => listas.expand((l) => l).toList());
      });
    });
  }

  /// Verificación previa (las reglas vuelven a comprobarlo en el servidor):
  /// nadie salvo el Admin General modera lo que él mismo creó.
  static Future<void> verificarModeracion({
    required AuthRepository auth,
    required DocumentReference creadoPor,
  }) async {
    final miRef = auth.requerirRefUsuario();
    final perfil = await auth.observarPerfilActual().first;
    if (PermisosModeracion.esAdmin(perfil)) return;
    if (!PermisosModeracion.puedeAbrirModeracion(perfil)) {
      throw const PermisoDenegadoException(
          'Tu cuenta no tiene permisos de moderación.');
    }
    if (creadoPor.path == miRef.path) {
      throw const PermisoDenegadoException(
          'No puedes aprobar ni rechazar algo que tú mismo creaste.');
    }
  }

  /// Borrado físico: solo el Admin General.
  static Future<void> exigirAdmin(AuthRepository auth) async {
    auth.requerirRefUsuario();
    final perfil = await auth.observarPerfilActual().first;
    PermisosModeracion.exigirAdmin(perfil);
  }
}
