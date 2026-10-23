import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_collections.dart';
import '../models/enums.dart';
import '../models/evento_model.dart';

/// CRUD y consultas de la colección `eventos`.
/// Cada consulta compuesta tiene su índice en firestore.indexes.json.
class EventoService {
  EventoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.eventos);

  DocumentReference<Map<String, dynamic>> refDe(String idEvento) =>
      _col.doc(idEvento);

  String nuevoId() => _col.doc().id;

  // ---------- Escritura ----------
  Future<void> crear(EventoModel evento) {
    return _col.doc(evento.idEvento).set(evento.toFirestore());
  }

  /// Crea varios eventos de una sola vez (recurrencia generada en la app,
  /// RF-4.4). Se escribe todo o nada, en lotes de máximo 500 operaciones.
  Future<void> crearVarios(List<EventoModel> eventos) async {
    const maxPorLote = 500;
    for (var i = 0; i < eventos.length; i += maxPorLote) {
      final lote = _db.batch();
      final fin =
          (i + maxPorLote < eventos.length) ? i + maxPorLote : eventos.length;
      for (final evento in eventos.sublist(i, fin)) {
        lote.set(_col.doc(evento.idEvento), evento.toFirestore());
      }
      await lote.commit();
    }
  }

  /// Guarda cambios. No toca `creado_por` ni `creado_en`.
  Future<void> actualizar(EventoModel evento) {
    final datos = evento.toFirestore()
      ..remove('creado_por')
      ..remove('creado_en');
    return _col.doc(evento.idEvento).update(datos);
  }

  /// Todos los Pendientes activos (solo Admin General). Sin orden en la
  /// consulta (solo igualdades): no requiere índice compuesto.
  Stream<List<EventoModel>> streamPendientes() {
    return _col
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.pendiente.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(EventoModel.fromFirestore).toList());
  }

  /// Pendientes de una iglesia (para su Pastor/Padre).
  Stream<List<EventoModel>> streamPendientesPorIglesia(
      DocumentReference iglesiaRef) {
    return _col
        .where('iglesia_ref', isEqualTo: iglesiaRef)
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.pendiente.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .snapshots()
        .map((q) => q.docs.map(EventoModel.fromFirestore).toList());
  }

  /// Moderación: solo cambia `estado_aprobacion` (lo único que las reglas
  /// permiten tocar a un aprobador que no es el creador).
  Future<void> cambiarEstadoAprobacion(String id, EstadoAprobacion estado) {
    return _col.doc(id).update({'estado_aprobacion': estado.value});
  }

  /// Borrado lógico (RF-4.6): solo el creador, su aprobador o el Admin.
  Future<void> eliminarLogico(String idEvento) {
    return _col
        .doc(idEvento)
        .update({'estado_logico': EstadoLogico.eliminado.value});
  }

  /// Borrado físico: solo el Administrador General.
  Future<void> eliminarFisico(String idEvento) {
    return _col.doc(idEvento).delete();
  }

  // ---------- Lectura ----------
  Future<EventoModel?> obtener(String idEvento) async {
    final snap = await _col.doc(idEvento).get();
    return snap.exists ? EventoModel.fromFirestore(snap) : null;
  }

  /// Base de toda consulta pública: Aprobado + Activo (coincide con las reglas).
  Query<Map<String, dynamic>> _publicos() {
    return _col
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.aprobado.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value);
  }

  /// Filtro de los próximos 30 días (RF-5.2), desde `desde` (por defecto: ahora).
  Query<Map<String, dynamic>> _enVentana(
    Query<Map<String, dynamic>> query, {
    DateTime? desde,
  }) {
    final inicio = desde ?? DateTime.now();
    final fin =
        inicio.add(const Duration(days: AppConstants.ventanaEventosDias));
    return query
        .where('fecha_hora_inicio',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha_hora_inicio', isLessThan: Timestamp.fromDate(fin))
        .orderBy('fecha_hora_inicio')
        .limit(AppConstants.maxEventosPorConsulta);
  }

  /// Todos los eventos públicos de los próximos 30 días (lista general).
  Stream<List<EventoModel>> streamProximos30Dias({DateTime? desde}) {
    return _enVentana(_publicos(), desde: desde)
        .snapshots()
        .map((q) => q.docs.map(EventoModel.fromFirestore).toList());
  }

  /// Eventos públicos de una iglesia en los próximos 30 días (Bottom Sheet, RF-5.1).
  Stream<List<EventoModel>> streamProximosPorIglesia(
    DocumentReference iglesiaRef, {
    DateTime? desde,
  }) {
    final base = _col
        .where('iglesia_ref', isEqualTo: iglesiaRef)
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.aprobado.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value);
    return _enVentana(base, desde: desde)
        .snapshots()
        .map((q) => q.docs.map(EventoModel.fromFirestore).toList());
  }

  /// Eventos públicos de un ministerio en los próximos 30 días.
  Stream<List<EventoModel>> streamProximosPorMinisterio(
    DocumentReference ministerioRef, {
    DateTime? desde,
  }) {
    final base = _col
        .where('ministerio_ref', isEqualTo: ministerioRef)
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.aprobado.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value);
    return _enVentana(base, desde: desde)
        .snapshots()
        .map((q) => q.docs.map(EventoModel.fromFirestore).toList());
  }

  /// Eventos creados por un usuario (incluye Pendientes, RF-4.5), del más nuevo al más antiguo.
  Stream<List<EventoModel>> streamDeCreador(DocumentReference creadorRef) {
    return _col
        .where('creado_por', isEqualTo: creadorRef)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .orderBy('fecha_hora_inicio', descending: true)
        .limit(AppConstants.maxEventosPorConsulta)
        .snapshots()
        .map((q) => q.docs.map(EventoModel.fromFirestore).toList());
  }

  /// Historial de eventos públicos ya pasados (RF-5.3), máximo 16 meses atrás (RF-5.4).
  Future<List<EventoModel>> obtenerHistorial({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final ahora = DateTime.now();
    final limiteInferior = DateTime(
      ahora.year,
      ahora.month - AppConstants.historialMaxMeses,
      ahora.day,
    );

    var inicio = desde ?? limiteInferior;
    if (inicio.isBefore(limiteInferior)) inicio = limiteInferior;

    var fin = hasta ?? ahora;
    if (fin.isAfter(ahora)) fin = ahora;

    final q = await _publicos()
        .where('fecha_hora_inicio',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha_hora_inicio', isLessThan: Timestamp.fromDate(fin))
        .orderBy('fecha_hora_inicio', descending: true)
        .limit(AppConstants.maxHistorialPorConsulta)
        .get();

    return q.docs.map(EventoModel.fromFirestore).toList();
  }

  /// Historial público de UNA iglesia (pestaña "Historial/Vencidos" del
  /// Bottom Sheet). Nunca más de 16 meses atrás (RF-5.4).
  Future<List<EventoModel>> obtenerHistorialPorIglesia(
    DocumentReference iglesiaRef, {
    DateTime? desde,
  }) async {
    final ahora = DateTime.now();
    final limiteInferior = DateTime(
      ahora.year,
      ahora.month - AppConstants.historialMaxMeses,
      ahora.day,
    );
    var inicio = desde ?? limiteInferior;
    if (inicio.isBefore(limiteInferior)) inicio = limiteInferior;

    final q = await _col
        .where('iglesia_ref', isEqualTo: iglesiaRef)
        .where('estado_aprobacion', isEqualTo: EstadoAprobacion.aprobado.value)
        .where('estado_logico', isEqualTo: EstadoLogico.activo.value)
        .where('fecha_hora_inicio',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha_hora_inicio', isLessThan: Timestamp.fromDate(ahora))
        .orderBy('fecha_hora_inicio', descending: true)
        .limit(AppConstants.maxHistorialPorConsulta)
        .get();

    return q.docs.map(EventoModel.fromFirestore).toList();
  }
}
