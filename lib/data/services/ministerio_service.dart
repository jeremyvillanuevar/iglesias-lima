import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/enums.dart';
import '../models/ministerio_model.dart';

/// CRUD de la colección `ministerios` (RF-3.1 a RF-3.3) y su moderación.
class MinisterioService {
  MinisterioService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.ministerios);

  DocumentReference<Map<String, dynamic>> refDe(String idMinisterio) =>
      _col.doc(idMinisterio);

  String nuevoId() => _col.doc().id;

  Future<void> crear(MinisterioModel ministerio) {
    return _col.doc(ministerio.idMinisterio).set(ministerio.toFirestore());
  }

  Future<MinisterioModel?> obtener(String idMinisterio) async {
    final snap = await _col.doc(idMinisterio).get();
    return snap.exists ? MinisterioModel.fromFirestore(snap) : null;
  }

  /// Ministerios aprobados de una iglesia matriz.
  Stream<List<MinisterioModel>> streamPublicosPorIglesia(
      DocumentReference iglesiaRef) {
    return _col
        .where('iglesia_ref', isEqualTo: iglesiaRef)
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.aprobado.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(MinisterioModel.fromFirestore).toList());
  }

  /// Ministerios que coordina un usuario, incluidos los Pendientes.
  Stream<List<MinisterioModel>> streamDeCoordinador(
      DocumentReference coordinadorRef) {
    return _col
        .where('coordinador_ref', isEqualTo: coordinadorRef)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(MinisterioModel.fromFirestore).toList());
  }

  /// Todos los Pendientes activos (solo Admin General).
  Stream<List<MinisterioModel>> streamPendientes() {
    return _col
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.pendiente.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(MinisterioModel.fromFirestore).toList());
  }

  /// Pendientes de una iglesia matriz (para su Pastor/Padre).
  Stream<List<MinisterioModel>> streamPendientesPorIglesia(
      DocumentReference iglesiaRef) {
    return _col
        .where('iglesia_ref', isEqualTo: iglesiaRef)
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.pendiente.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(MinisterioModel.fromFirestore).toList());
  }

  /// Moderación: solo cambia `estado_aprobacion` (lo único que las reglas
  /// permiten tocar a un aprobador que no es el creador).
  Future<void> cambiarEstadoAprobacion(String id, EstadoAprobacion estado) {
    return _col.doc(id).update({'estado_aprobacion': estado.value});
  }

  Future<void> actualizar(MinisterioModel ministerio) {
    final datos = ministerio.toFirestore()
      ..remove('creado_por')
      ..remove('creado_en');
    return _col.doc(ministerio.idMinisterio).update(datos);
  }

  Future<void> eliminarLogico(String idMinisterio) {
    return _col
        .doc(idMinisterio)
        .update({'estado_logico': EstadoLogico.eliminado.value});
  }

  Future<void> eliminarFisico(String idMinisterio) {
    return _col.doc(idMinisterio).delete();
  }
}
