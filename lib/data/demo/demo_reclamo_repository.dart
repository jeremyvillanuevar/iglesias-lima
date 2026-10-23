import 'package:rxdart/rxdart.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/enums.dart';
import '../models/iglesia_model.dart';
import '../models/solicitud_reclamo_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/permisos_moderacion.dart';
import '../repositories/reclamo_repository.dart';
import '../repositories/reglas_reclamo.dart';
import '../repositories/reglas_validacion.dart';
import 'demo_copias.dart';
import 'demo_data_store.dart';

/// Reclamos en memoria (Modo Demo), con las mismas reglas que Firestore.
class DemoReclamoRepository implements ReclamoRepository {
  DemoReclamoRepository(this._store, this._auth);

  final DemoDataStore _store;
  final AuthRepository _auth;

  static const String _accionAprobar =
      'aprobar o rechazar reclamos de iglesias';

  @override
  Stream<SolicitudReclamoModel?> observarMiSolicitud(String idIglesia) {
    return Rx.combineLatest2(
      _store.solicitudesReclamo,
      _auth.observarUid(),
      (List<SolicitudReclamoModel> lista, String? uid) {
        if (uid == null) return null;
        final id = SolicitudReclamoModel.idPara(idIglesia: idIglesia, uid: uid);
        for (final s in lista) {
          if (s.idSolicitud == id) return s;
        }
        return null;
      },
    );
  }

  @override
  Future<void> reclamar({
    required IglesiaModel iglesia,
    required String cargo,
    String? mensaje,
  }) async {
    final miRef = _auth.requerirRefUsuario();
    final perfil = _store.usuarioActual.value;
    if (perfil == null) throw const SesionRequeridaException();
    final actual = _store.iglesiaPorPath(
            '${FirestoreCollections.iglesias}/${iglesia.idIglesia}') ??
        iglesia;
    final id = SolicitudReclamoModel.idPara(
        idIglesia: actual.idIglesia, uid: perfil.uid);
    ReglasReclamo.validarNueva(
      iglesia: actual,
      cargo: cargo,
      mensaje: mensaje,
      existente: _porId(id),
    );
    await _store.esperar();
    final solicitud = SolicitudReclamoModel(
      idSolicitud: id,
      idIglesia: actual.idIglesia,
      iglesiaRef: _store.ref(FirestoreCollections.iglesias, actual.idIglesia),
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
      estado: EstadoAprobacion.pendiente,
      creadoEn: DateTime.now(),
    );
    _store.solicitudesReclamo.add([
      for (final s in _store.solicitudesReclamo.value)
        if (s.idSolicitud != id) s,
      solicitud,
    ]);
    if (actual.estadoAdministracion == EstadoAdministracion.sinAdministrador) {
      _store.reemplazarIglesia(DemoCopias.iglesia(actual,
          estadoAdministracion: EstadoAdministracion.reclamacionPendiente));
    }
  }

  @override
  Stream<List<SolicitudReclamoModel>> observarPendientes() {
    return Rx.combineLatest2(
      _store.solicitudesReclamo,
      _store.usuarioActual,
      (List<SolicitudReclamoModel> lista, usuario) {
        if (!PermisosModeracion.esAdmin(usuario)) {
          return const <SolicitudReclamoModel>[];
        }
        return lista.where((s) => s.estaPendiente).toList()
          ..sort((a, b) =>
              (b.creadoEn ?? DateTime(0)).compareTo(a.creadoEn ?? DateTime(0)));
      },
    );
  }

  @override
  Future<void> aprobar(String idSolicitud) async {
    final miRef = _auth.requerirRefUsuario();
    PermisosModeracion.exigirAdminPara(
        _store.usuarioActual.value, _accionAprobar);
    final s = _porId(idSolicitud);
    ReglasReclamo.exigirPendiente(s);
    final iglesia = _store.iglesiaPorPath(s!.iglesiaRef.path);
    if (iglesia == null) throw ArgumentError('La iglesia ya no existe.');
    if (iglesia.esAdministrada) {
      throw ArgumentError('Esta iglesia ya tiene un administrador.');
    }
    await _store.esperar();
    final ahora = DateTime.now();
    _store.solicitudesReclamo.add([
      for (final o in _store.solicitudesReclamo.value)
        if (o.idSolicitud == idSolicitud)
          o.resuelta(
              estado: EstadoAprobacion.aprobado,
              resueltoPor: miRef,
              resueltoEn: ahora)
        else if (o.idIglesia == s.idIglesia && o.estaPendiente)
          o.resuelta(
              estado: EstadoAprobacion.rechazado,
              resueltoPor: miRef,
              resueltoEn: ahora)
        else
          o,
    ]);
    _store.reemplazarIglesia(DemoCopias.iglesia(
      iglesia,
      liderUidRef: s.solicitanteRef,
      liderNombreTexto: iglesia.liderNombreTexto ?? s.nombreSolicitante,
      estadoAdministracion: EstadoAdministracion.administrada,
    ));
    final usuario = _store.usuarioPorUid(s.uidSolicitante);
    if (usuario != null) {
      final rol = ReglasReclamo.rolTrasAprobar(usuario.rolGlobal);
      if (rol != usuario.rolGlobal) {
        _store.cambiarRolDeUsuario(usuario.uid, rol);
      }
    }
  }

  @override
  Future<void> rechazar(String idSolicitud) async {
    final miRef = _auth.requerirRefUsuario();
    PermisosModeracion.exigirAdminPara(
        _store.usuarioActual.value, _accionAprobar);
    final s = _porId(idSolicitud);
    ReglasReclamo.exigirPendiente(s);
    await _store.esperar();
    _store.solicitudesReclamo.add([
      for (final o in _store.solicitudesReclamo.value)
        o.idSolicitud == idSolicitud
            ? o.resuelta(
                estado: EstadoAprobacion.rechazado,
                resueltoPor: miRef,
                resueltoEn: DateTime.now())
            : o,
    ]);
    final quedan = _store.solicitudesReclamo.value
        .any((o) => o.idIglesia == s!.idIglesia && o.estaPendiente);
    final iglesia = _store.iglesiaPorPath(s!.iglesiaRef.path);
    if (iglesia != null && !iglesia.esAdministrada && !quedan) {
      _store.reemplazarIglesia(DemoCopias.iglesia(iglesia,
          estadoAdministracion: EstadoAdministracion.sinAdministrador));
    }
  }

  SolicitudReclamoModel? _porId(String id) {
    for (final s in _store.solicitudesReclamo.value) {
      if (s.idSolicitud == id) return s;
    }
    return null;
  }
}
