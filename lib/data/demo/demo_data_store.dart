import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;
import 'package:rxdart/rxdart.dart';

import '../models/evento_model.dart';
import '../models/iglesia_model.dart';
import '../models/enums.dart';
import '../models/ministerio_model.dart';
import '../models/solicitud_reclamo_model.dart';
import '../models/user_model.dart';
import 'demo_copias.dart';
import 'demo_datos_semilla.dart';
import 'demo_document_reference.dart';

/// "Base de datos" en memoria del Modo Demo. Todo se pierde al cerrar la app.
class DemoDataStore {
  DemoDataStore({DateTime? ahora, Duration? latenciaSimulada})
      : latencia = latenciaSimulada ?? const Duration(milliseconds: 350) {
    final semilla = DemoDatosSemilla(ahora: ahora);
    iglesias.add(semilla.iglesias());
    eventos.add(semilla.eventos());
    ministerios.add(semilla.ministerios());
  }

  /// Pequeña espera para que la app se sienta como con internet real.
  final Duration latencia;

  final BehaviorSubject<List<IglesiaModel>> iglesias =
      BehaviorSubject.seeded(const []);
  final BehaviorSubject<List<EventoModel>> eventos =
      BehaviorSubject.seeded(const []);
  final BehaviorSubject<List<MinisterioModel>> ministerios =
      BehaviorSubject.seeded(const []);

  /// Importadas de OSM descartadas por el Admin General, por denominación
  /// (ids de documento de `DescarteOsm.idDocumento`).
  final Set<String> osmDescartadas = {};

  final BehaviorSubject<List<SolicitudReclamoModel>> solicitudesReclamo =
      BehaviorSubject.seeded(const []);
  final BehaviorSubject<UserModel?> usuarioActual =
      BehaviorSubject.seeded(null);

  /// Usuarios registrados en esta sesión de la app: correo -> perfil.
  final Map<String, UserModel> usuariosPorCorreo = {};

  /// Contraseñas simuladas: correo -> contraseña (solo en memoria).
  final Map<String, String> contrasenasPorCorreo = {};

  /// Quién es hoy el dueño de los Pendientes de ejemplo.
  String _pathDuenoSemilla = DemoDatosSemilla.pathCreadorSemilla;

  /// Quién es hoy el Pastor/Padre (líder) de las iglesias de ejemplo con líder.
  String _pathLiderSemilla = DemoDatosSemilla.pathPastorSemilla;

  int _contador = 0;

  String nuevoId(String prefijo) {
    _contador++;
    return '$prefijo-${DateTime.now().microsecondsSinceEpoch}-$_contador';
  }

  DocumentReference<Map<String, dynamic>> ref(String coleccion, String id) =>
      DemoDocumentReference('$coleccion/$id');

  Future<void> esperar() => Future<void>.delayed(latencia);

  /// Iglesia por su ruta 'iglesias/{id}' (o null).
  IglesiaModel? iglesiaPorPath(String? path) {
    if (path == null) return null;
    for (final i in iglesias.value) {
      if ('iglesias/${i.idIglesia}' == path) return i;
    }
    return null;
  }

  /// Ministerio por su ruta 'ministerios/{id}' (o null).
  MinisterioModel? ministerioPorPath(String? path) {
    if (path == null) return null;
    for (final m in ministerios.value) {
      if ('ministerios/${m.idMinisterio}' == path) return m;
    }
    return null;
  }

  /// Reemplaza la iglesia con el mismo id.
  void reemplazarIglesia(IglesiaModel iglesia) {
    iglesias.add([
      for (final i in iglesias.value)
        i.idIglesia == iglesia.idIglesia ? iglesia : i,
    ]);
  }

  /// Perfil de un usuario registrado en esta sesión (o null).
  UserModel? usuarioPorUid(String uid) {
    final actual = usuarioActual.value;
    if (actual?.uid == uid) return actual;
    for (final u in usuariosPorCorreo.values) {
      if (u.uid == uid) return u;
    }
    return null;
  }

  /// Cambia el rol de un usuario (y del usuario actual si es el mismo).
  void cambiarRolDeUsuario(String uid, RolGlobal rol) {
    final u = usuarioPorUid(uid);
    if (u == null) return;
    final nuevo = DemoCopias.usuario(u, rolGlobal: rol);
    usuariosPorCorreo[nuevo.email] = nuevo;
    if (usuarioActual.value?.uid == uid) usuarioActual.add(nuevo);
  }

  /// El usuario que entra pasa a ser el Pastor/Padre (líder) de las iglesias
  /// de ejemplo que tienen líder, para poder probar la Moderación como
  /// aprobador. Los Pendientes que creó otro usuario de ejemplo quedan
  /// disponibles para aprobar o rechazar.
  void reasignarLiderazgoDeEjemploA(DocumentReference nuevoLider) {
    final anterior = _pathLiderSemilla;
    if (anterior == nuevoLider.path) return;
    iglesias.add([
      for (final i in iglesias.value)
        i.liderUidRef?.path == anterior
            ? DemoCopias.iglesia(i, liderUidRef: nuevoLider)
            : i,
    ]);
    _pathLiderSemilla = nuevoLider.path;
  }

  /// Pasa los elementos Pendientes de ejemplo al usuario que acaba de entrar,
  /// para que pueda ver cómo se muestra el chip "Pendiente".
  void reasignarPendientesDeEjemploA(DocumentReference nuevoDueno) {
    final anterior = _pathDuenoSemilla;
    if (anterior == nuevoDueno.path) return;
    iglesias.add([
      for (final i in iglesias.value)
        i.creadoPor.path == anterior
            ? DemoCopias.iglesia(i, creadoPor: nuevoDueno)
            : i,
    ]);
    eventos.add([
      for (final e in eventos.value)
        e.creadoPor.path == anterior
            ? DemoCopias.evento(e, creadoPor: nuevoDueno)
            : e,
    ]);
    ministerios.add([
      for (final m in ministerios.value)
        m.creadoPor.path == anterior
            ? DemoCopias.ministerio(m, creadoPor: nuevoDueno)
            : m,
    ]);
    _pathDuenoSemilla = nuevoDueno.path;
  }

  Future<void> cerrar() async {
    await iglesias.close();
    await eventos.close();
    await ministerios.close();
    await solicitudesReclamo.close();
    await usuarioActual.close();
  }
}
