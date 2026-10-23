import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/descarte_osm.dart';
import '../models/enums.dart';
import '../models/iglesia_model.dart';

/// CRUD de la colección `iglesias`.
class IglesiaService {
  IglesiaService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.iglesias);

  DocumentReference<Map<String, dynamic>> refDe(String idIglesia) =>
      _col.doc(idIglesia);

  /// Genera un id nuevo sin escribir nada todavía.
  String nuevoId() => _col.doc().id;

  Future<void> crear(IglesiaModel iglesia) {
    return _col.doc(iglesia.idIglesia).set(iglesia.toFirestore());
  }

  /// Ids de las iglesias que ya existen con ese [origen] (para importar sin
  /// duplicar). Solo el Admin General puede leerlas todas.
  Future<Set<String>> idsPorOrigen(OrigenIglesia origen) async {
    final q = await _col.where('origen', isEqualTo: origen.value).get();
    return q.docs.map((d) => d.id).toSet();
  }

  /// Importadas de OSM con la denominación "Por verificar" (Admin General).
  Stream<List<IglesiaModel>> streamPorVerificar() {
    return _col
        .where('verificacion_denominacion',
            isEqualTo: VerificacionDenominacion.porVerificar.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(IglesiaModel.fromFirestore).toList());
  }

  /// El Admin General confirma la denominación de una importada.
  Future<void> confirmarDenominacion(String idIglesia) {
    return _col.doc(idIglesia).update({
      'verificacion_denominacion': VerificacionDenominacion.confirmadaOsm.value,
    });
  }

  CollectionReference<Map<String, dynamic>> get _descartadas =>
      _db.collection(FirestoreCollections.osmDescartadas);

  /// Ids de iglesia ('osm_<tipo>_<id>') que el Admin General ya descartó
  /// para [denominacion] (los descartes antiguos cuentan como católicos).
  Future<Set<String>> idsOsmDescartados(Denominacion denominacion) async {
    final q = await _descartadas.get();
    return {
      for (final d in q.docs)
        if (DescarteOsm.denominacionDe(d.data()) == denominacion)
          DescarteOsm.idIglesiaDe(d.id, d.data()),
    };
  }

  /// Borra una importada y la anota como descartada, en una sola escritura.
  Future<void> descartarImportada({
    required String idIglesia,
    required String? osmId,
    required Denominacion denominacion,
    required DocumentReference descartadaPor,
  }) {
    return (_db.batch()
          ..delete(_col.doc(idIglesia))
          ..set(
              _descartadas
                  .doc(DescarteOsm.idDocumento(denominacion, idIglesia)),
              {
                'id_iglesia': idIglesia,
                'denominacion': denominacion.value,
                'osm_id': osmId,
                'descartada_por': descartadaPor,
                'descartada_en': FieldValue.serverTimestamp(),
              }))
        .commit();
  }

  /// Crea varias iglesias en una sola escritura (máx. 500 por lote).
  Future<void> crearEnLote(List<IglesiaModel> iglesias) {
    final lote = _db.batch();
    for (final i in iglesias) {
      lote.set(_col.doc(i.idIglesia), i.toFirestore());
    }
    return lote.commit();
  }

  Future<IglesiaModel?> obtener(String idIglesia) async {
    final snap = await _col.doc(idIglesia).get();
    return snap.exists ? IglesiaModel.fromFirestore(snap) : null;
  }

  /// Iglesias aprobadas y activas de una localidad (pines públicos del mapa).
  Stream<List<IglesiaModel>> streamPublicas({required String localidad}) {
    return _col
        .where('localidad', isEqualTo: localidad)
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.aprobado.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(IglesiaModel.fromFirestore).toList());
  }

  /// Iglesias creadas por un usuario, incluidas las Pendientes (RF-2.4).
  Stream<List<IglesiaModel>> streamDeCreador(DocumentReference creadorRef) {
    return _col
        .where('creado_por', isEqualTo: creadorRef)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(IglesiaModel.fromFirestore).toList());
  }

  /// Iglesias que lidera un Pastor/Padre (`lider_uid_ref`).
  Stream<List<IglesiaModel>> streamDeLider(DocumentReference liderRef) {
    return _col
        .where('lider_uid_ref', isEqualTo: liderRef)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(IglesiaModel.fromFirestore).toList());
  }

  /// Todas las Pendientes activas (solo el Admin General puede leerlas).
  Stream<List<IglesiaModel>> streamPendientes() {
    return _col
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.pendiente.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(IglesiaModel.fromFirestore).toList());
  }

  /// Pendientes de las que el usuario es líder (aprobador).
  Stream<List<IglesiaModel>> streamPendientesDeLider(
      DocumentReference liderRef) {
    return _col
        .where('lider_uid_ref', isEqualTo: liderRef)
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.pendiente.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(IglesiaModel.fromFirestore).toList());
  }

  /// Moderación: solo cambia `estado_aprobacion` (lo único que las reglas
  /// permiten tocar a un aprobador que no es el creador).
  Future<void> cambiarEstadoAprobacion(String id, EstadoAprobacion estado) {
    return _col.doc(id).update({'estado_aprobacion': estado.value});
  }

  /// Guarda los cambios de una iglesia existente.
  /// No toca `creado_por`, `creado_en` ni los datos de administración
  /// (`estado_administracion`, `origen`, `osm_id`, `criterio_osm`), que solo cambian al
  /// reclamar, aprobar un reclamo o importar.
  Future<void> actualizar(IglesiaModel iglesia) {
    final datos = iglesia.toFirestore()
      ..remove('creado_por')
      ..remove('creado_en')
      ..remove('estado_administracion')
      ..remove('origen')
      ..remove('osm_id')
      ..remove('verificacion_denominacion')
      ..remove('criterio_osm');
    return _col.doc(iglesia.idIglesia).update(datos);
  }

  /// Borrado lógico (RF-2.5): la iglesia deja de verse, pero sigue en la base.
  Future<void> eliminarLogico(String idIglesia) {
    return _col
        .doc(idIglesia)
        .update({'estado_logico': EstadoLogico.eliminado.value});
  }

  /// Borrado físico: las reglas solo lo permiten al Administrador General.
  Future<void> eliminarFisico(String idIglesia) {
    return _col.doc(idIglesia).delete();
  }
}
