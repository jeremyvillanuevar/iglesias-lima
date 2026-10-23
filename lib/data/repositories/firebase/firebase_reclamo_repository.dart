import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;
import 'package:rxdart/rxdart.dart';

import '../../models/enums.dart';
import '../../models/iglesia_model.dart';
import '../../models/solicitud_reclamo_model.dart';
import '../../services/iglesia_service.dart';
import '../../services/solicitud_reclamo_service.dart';
import '../../services/user_service.dart';
import '../auth_repository.dart';
import '../permisos_moderacion.dart';
import '../reclamo_repository.dart';
import '../reglas_reclamo.dart';
import '../reglas_validacion.dart';

/// Reclamos guardados en Firestore (colección `solicitudes_reclamo`).
class FirebaseReclamoRepository implements ReclamoRepository {
  FirebaseReclamoRepository({
    required SolicitudReclamoService solicitudService,
    required IglesiaService iglesiaService,
    required UserService userService,
    required AuthRepository authRepository,
  })  : _service = solicitudService,
        _iglesias = iglesiaService,
        _users = userService,
        _auth = authRepository;

  final SolicitudReclamoService _service;
  final IglesiaService _iglesias;
  final UserService _users;
  final AuthRepository _auth;

  static const String _accionAprobar =
      'aprobar o rechazar reclamos de iglesias';

  @override
  Stream<SolicitudReclamoModel?> observarMiSolicitud(String idIglesia) {
    return _auth.observarUid().switchMap((uid) {
      if (uid == null) return Stream<SolicitudReclamoModel?>.value(null);
      return _service.observar(
          SolicitudReclamoModel.idPara(idIglesia: idIglesia, uid: uid));
    });
  }

  @override
  Future<void> reclamar({
    required IglesiaModel iglesia,
    required String cargo,
    String? mensaje,
  }) async {
    final miRef = _auth.requerirRefUsuario();
    final perfil = await _auth.observarPerfilActual().first;
    if (perfil == null) throw const SesionRequeridaException();
    final actual = await _iglesias.obtener(iglesia.idIglesia) ?? iglesia;
    final id = SolicitudReclamoModel.idPara(
        idIglesia: actual.idIglesia, uid: perfil.uid);
    final existente = await _service.obtener(id);
    ReglasReclamo.validarNueva(
      iglesia: actual,
      cargo: cargo,
      mensaje: mensaje,
      existente: existente,
    );
    final solicitud = SolicitudReclamoModel.nueva(
      idIglesia: actual.idIglesia,
      iglesiaRef: _iglesias.refDe(actual.idIglesia),
      nombreIglesia: actual.nombre,
      denominacion: actual.denominacion,
      uidSolicitante: perfil.uid,
      solicitanteRef: miRef,
      nombreSolicitante: perfil.nombreCompleto.isNotEmpty
          ? perfil.nombreCompleto
          : perfil.email,
      emailSolicitante: perfil.email,
      cargo: cargo.trim(),
      mensaje: ReglasValidacion.limpio(mensaje),
    );
    await _service.enviar(
      solicitud,
      marcarIglesia:
          actual.estadoAdministracion == EstadoAdministracion.sinAdministrador,
    );
  }

  @override
  Stream<List<SolicitudReclamoModel>> observarPendientes() {
    return _auth.observarPerfilActual().switchMap((perfil) {
      if (!PermisosModeracion.esAdmin(perfil)) {
        return Stream<List<SolicitudReclamoModel>>.value(const []);
      }
      return _service.streamPendientes();
    });
  }

  @override
  Future<void> aprobar(String idSolicitud) async {
    final miRef = await _exigirAdmin();
    final solicitud = await _service.obtener(idSolicitud);
    ReglasReclamo.exigirPendiente(solicitud);
    final s = solicitud!;
    final iglesia = await _iglesias.obtener(s.idIglesia);
    if (iglesia == null) throw ArgumentError('La iglesia ya no existe.');
    if (iglesia.esAdministrada) {
      throw ArgumentError('Esta iglesia ya tiene un administrador.');
    }
    final usuario = await _users.obtener(s.uidSolicitante);
    if (usuario == null) {
      throw ArgumentError('La cuenta del solicitante ya no existe.');
    }
    final rol = ReglasReclamo.rolTrasAprobar(usuario.rolGlobal);
    final otras = (await _service.pendientesDeIglesia(s.iglesiaRef))
        .where((o) => o.idSolicitud != s.idSolicitud)
        .toList();
    await _service.aprobar(
      solicitud: s,
      resueltoPor: miRef,
      nuevoRol: rol == usuario.rolGlobal ? null : rol,
      asignarNombreLider: iglesia.liderNombreTexto == null,
      otras: otras,
    );
  }

  @override
  Future<void> rechazar(String idSolicitud) async {
    final miRef = await _exigirAdmin();
    final solicitud = await _service.obtener(idSolicitud);
    ReglasReclamo.exigirPendiente(solicitud);
    final s = solicitud!;
    final iglesia = await _iglesias.obtener(s.idIglesia);
    final otras = (await _service.pendientesDeIglesia(s.iglesiaRef))
        .where((o) => o.idSolicitud != s.idSolicitud);
    await _service.rechazar(
      solicitud: s,
      resueltoPor: miRef,
      liberarIglesia:
          iglesia != null && !iglesia.esAdministrada && otras.isEmpty,
    );
  }

  Future<DocumentReference> _exigirAdmin() async {
    final miRef = _auth.requerirRefUsuario();
    final perfil = await _auth.observarPerfilActual().first;
    PermisosModeracion.exigirAdminPara(perfil, _accionAprobar);
    return miRef;
  }
}
