import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/enums.dart';
import '../models/solicitud_reclamo_model.dart';

/// Colección `solicitudes_reclamo` y las escrituras en lote que tocan
/// también `iglesias` y `users` al aprobar o rechazar.
class SolicitudReclamoService {
  SolicitudReclamoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.solicitudesReclamo);

  DocumentReference<Map<String, dynamic>> refDe(String idSolicitud) =>
      _col.doc(idSolicitud);

  Future<SolicitudReclamoModel?> obtener(String idSolicitud) async {
    final snap = await _col.doc(idSolicitud).get();
    return snap.exists ? SolicitudReclamoModel.fromFirestore(snap) : null;
  }

  Stream<SolicitudReclamoModel?> observar(String idSolicitud) {
    return _col
        .doc(idSolicitud)
        .snapshots()
        .map((s) => s.exists ? SolicitudReclamoModel.fromFirestore(s) : null);
  }

  /// Todas las Pendientes, más recientes primero (solo Admin General).
  Stream<List<SolicitudReclamoModel>> streamPendientes() {
    return _col
        .where('estado', isEqualTo: EstadoAprobacion.pendiente.value)
        .orderBy('creado_en', descending: true)
        .snapshots()
        .map((q) => q.docs.map(SolicitudReclamoModel.fromFirestore).toList());
  }

  /// Pendientes de una iglesia (solo Admin General).
  Future<List<SolicitudReclamoModel>> pendientesDeIglesia(
      DocumentReference iglesiaRef) async {
    final q = await _col
        .where('iglesia_ref', isEqualTo: iglesiaRef)
        .where('estado', isEqualTo: EstadoAprobacion.pendiente.value)
        .get();
    return q.docs.map(SolicitudReclamoModel.fromFirestore).toList();
  }

  /// Guarda la solicitud y, si [marcarIglesia], pasa la iglesia a
  /// "Reclamacion_Pendiente" en la misma escritura (las reglas exigen que
  /// la solicitud exista al terminar el lote).
  Future<void> enviar(SolicitudReclamoModel solicitud,
      {required bool marcarIglesia}) {
    final lote = _db.batch()
      ..set(_col.doc(solicitud.idSolicitud), solicitud.toFirestore());
    if (marcarIglesia) {
      lote.update(solicitud.iglesiaRef, {
        'estado_administracion':
            EstadoAdministracion.reclamacionPendiente.value,
      });
    }
    return lote.commit();
  }

  /// Aprobar: la solicitud pasa a Aprobado, el solicitante queda como líder
  /// de la iglesia ("Administrada"), recibe [nuevoRol] y [otras] quedan
  /// Rechazadas.
  Future<void> aprobar({
    required SolicitudReclamoModel solicitud,
    required DocumentReference resueltoPor,
    required RolGlobal? nuevoRol,
    required bool asignarNombreLider,
    required List<SolicitudReclamoModel> otras,
  }) {
    final lote = _db.batch()
      ..update(_col.doc(solicitud.idSolicitud),
          _resolucion(EstadoAprobacion.aprobado, resueltoPor))
      ..update(solicitud.iglesiaRef, {
        'lider_uid_ref': solicitud.solicitanteRef,
        'estado_administracion': EstadoAdministracion.administrada.value,
        if (asignarNombreLider)
          'lider_nombre_texto': solicitud.nombreSolicitante,
      });
    if (nuevoRol != null) {
      lote.update(solicitud.solicitanteRef, {'rol_global': nuevoRol.value});
    }
    for (final o in otras) {
      lote.update(_col.doc(o.idSolicitud),
          _resolucion(EstadoAprobacion.rechazado, resueltoPor));
    }
    return lote.commit();
  }

  /// Rechazar; si [liberarIglesia], la iglesia vuelve a "Sin_Administrador".
  Future<void> rechazar({
    required SolicitudReclamoModel solicitud,
    required DocumentReference resueltoPor,
    required bool liberarIglesia,
  }) {
    final lote = _db.batch()
      ..update(_col.doc(solicitud.idSolicitud),
          _resolucion(EstadoAprobacion.rechazado, resueltoPor));
    if (liberarIglesia) {
      lote.update(solicitud.iglesiaRef, {
        'estado_administracion': EstadoAdministracion.sinAdministrador.value,
      });
    }
    return lote.commit();
  }

  Map<String, dynamic> _resolucion(
          EstadoAprobacion estado, DocumentReference resueltoPor) =>
      {
        'estado': estado.value,
        'resuelto_por': resueltoPor,
        'resuelto_en': FieldValue.serverTimestamp(),
      };
}
