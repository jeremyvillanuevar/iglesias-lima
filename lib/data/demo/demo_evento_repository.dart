import 'package:rxdart/rxdart.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_collections.dart';
import '../models/enums.dart';
import '../models/evento_model.dart';
import '../recurrencia/ocurrencia_evento.dart';
import '../repositories/auth_repository.dart';
import '../repositories/evento_repository.dart';
import '../repositories/permisos_moderacion.dart';
import '../repositories/reglas_validacion.dart';
import 'demo_copias.dart';
import 'demo_data_store.dart';

/// Eventos en memoria (Modo Demo), con las mismas ventanas de tiempo que la
/// versión Firebase: próximos 30 días e historial de máximo 16 meses.
class DemoEventoRepository implements EventoRepository {
  DemoEventoRepository(this._store, this._auth);

  final DemoDataStore _store;
  final AuthRepository _auth;

  @override
  Future<EventoModel?> obtener(String idEvento) async {
    final lista = _store.eventos.value.where((e) => e.idEvento == idEvento);
    if (lista.isEmpty) return null;
    final e = lista.first;
    return _esPublico(e) || _esMio(e, _auth.refUsuarioActual?.path) ? e : null;
  }

  @override
  Stream<List<EventoModel>> observarProximos30Dias() {
    return _store.eventos.map((lista) =>
        _ordenar(lista.where((e) => _esPublico(e) && _enVentana(e))));
  }

  @override
  Stream<List<EventoModel>> observarProximosVisibles() {
    return _visibles().map((lista) => _ordenar(lista.where(_enVentana)));
  }

  @override
  Stream<List<EventoModel>> observarEventosDeIglesia(String idIglesia) {
    final path = '${FirestoreCollections.iglesias}/$idIglesia';
    return _visibles().map((lista) => _ordenar(
        lista.where((e) => e.iglesiaRef?.path == path && _enVentana(e))));
  }

  @override
  Stream<List<EventoModel>> observarEventosDeMinisterio(String idMinisterio) {
    final path = '${FirestoreCollections.ministerios}/$idMinisterio';
    return _store.eventos.map((lista) => _ordenar(lista.where((e) =>
        e.ministerioRef?.path == path && _esPublico(e) && _enVentana(e))));
  }

  @override
  Stream<List<EventoModel>> observarMisEventos() {
    return Rx.combineLatest2<List<EventoModel>, String?, List<EventoModel>>(
      _store.eventos,
      _auth.observarUid(),
      (lista, uid) {
        final miPath = _auth.refUsuarioActual?.path;
        if (uid == null || miPath == null) return const [];
        return _ordenar(lista.where((e) => _esMio(e, miPath)),
            descendente: true);
      },
    );
  }

  @override
  Future<List<EventoModel>> obtenerHistorial(
      {DateTime? desde, DateTime? hasta}) async {
    await _store.esperar();
    return _historial(_store.eventos.value.where(_esPublico),
        desde: desde, hasta: hasta);
  }

  @override
  Future<List<EventoModel>> obtenerHistorialDeIglesia(
    String idIglesia, {
    DateTime? desde,
  }) async {
    await _store.esperar();
    final path = '${FirestoreCollections.iglesias}/$idIglesia';
    return _historial(
      _store.eventos.value
          .where((e) => _esPublico(e) && e.iglesiaRef?.path == path),
      desde: desde,
    );
  }

  @override
  Future<String> crearEvento({
    required TipoActividad tipoActividad,
    required String titulo,
    required String categoria,
    required DateTime fechaHoraInicio,
    DateTime? fechaHoraFin,
    String? descripcion,
    String? idIglesia,
    String? idMinisterio,
    bool esVirtual = false,
    String? linkVirtual,
    String? imagenUrl,
  }) async {
    final ids = await crearEventos(
      DatosNuevoEvento(
        tipoActividad: tipoActividad,
        titulo: titulo,
        categoria: categoria,
        descripcion: descripcion,
        idIglesia: idIglesia,
        idMinisterio: idMinisterio,
        esVirtual: esVirtual,
        linkVirtual: linkVirtual,
        imagenUrl: imagenUrl,
        duracion: fechaHoraFin?.difference(fechaHoraInicio),
      ),
      [OcurrenciaEvento(inicio: fechaHoraInicio)],
    );
    return ids.first;
  }

  @override
  Future<List<String>> crearEventos(
    DatosNuevoEvento datos,
    List<OcurrenciaEvento> ocurrencias,
  ) async {
    final creadoPor = _auth.requerirRefUsuario();
    ReglasValidacion.validarEvento(datos, ocurrencias);
    await _store.esperar();

    final ahora = DateTime.now();
    final nuevos = [
      for (final o in ocurrencias)
        DemoCopias.evento(
          EventoModel.nuevo(
            idEvento: _store.nuevoId('demo-evento'),
            tipoActividad: datos.tipoActividad,
            titulo: datos.titulo.trim(),
            categoria: datos.categoria.trim(),
            descripcion: ReglasValidacion.limpio(datos.descripcion),
            iglesiaRef: datos.idIglesia == null
                ? null
                : _store.ref(FirestoreCollections.iglesias, datos.idIglesia!),
            ministerioRef: datos.idMinisterio == null
                ? null
                : _store.ref(
                    FirestoreCollections.ministerios, datos.idMinisterio!),
            fechaHoraInicio: o.inicio,
            fechaHoraFin:
                datos.duracion == null ? null : o.inicio.add(datos.duracion!),
            esVirtual: datos.esVirtual,
            linkVirtual: ReglasValidacion.limpio(datos.linkVirtual),
            imagenUrl: ReglasValidacion.limpio(datos.imagenUrl),
            esRecurrente: o.esRecurrente,
            patronRecurrencia: o.patronRecurrencia,
            creadoPor: creadoPor,
          ),
          creadoEn: ahora,
        ),
    ];
    // Igual que un batch: se agregan todos juntos o ninguno.
    _store.eventos.add([..._store.eventos.value, ...nuevos]);
    return nuevos.map((e) => e.idEvento).toList();
  }

  @override
  Future<void> actualizar(EventoModel evento) async {
    _auth.requerirRefUsuario();
    await _store.esperar();
    _store.eventos.add([
      for (final e in _store.eventos.value)
        e.idEvento == evento.idEvento ? evento : e,
    ]);
  }

  @override
  Future<void> eliminar(String idEvento) async {
    _auth.requerirRefUsuario();
    _store.eventos.add([
      for (final e in _store.eventos.value)
        e.idEvento == idEvento
            ? DemoCopias.evento(e, estadoLogico: EstadoLogico.eliminado)
            : e,
    ]);
  }

  // ---------- Moderación ----------
  @override
  Stream<List<EventoModel>> observarPendientesDeModeracion() {
    return Rx.combineLatest3(
      _store.eventos,
      _store.iglesias,
      _store.usuarioActual,
      (List<EventoModel> lista, _, usuario) {
        if (!PermisosModeracion.puedeAbrirModeracion(usuario)) {
          return const <EventoModel>[];
        }
        final esAdmin = PermisosModeracion.esAdmin(usuario);
        final miPath = _auth.refUsuarioActual?.path;
        return _ordenar(lista.where((e) =>
            e.estadoAprobacion == EstadoAprobacion.pendiente &&
            e.estadoLogico == EstadoLogico.activo &&
            (esAdmin || _liderDeIglesia(e) == miPath)));
      },
    );
  }

  @override
  Future<void> aprobar(String idEvento) =>
      _moderar(idEvento, EstadoAprobacion.aprobado);

  @override
  Future<void> rechazar(String idEvento) =>
      _moderar(idEvento, EstadoAprobacion.rechazado);

  Future<void> _moderar(String idEvento, EstadoAprobacion nuevo) async {
    final miRef = _auth.requerirRefUsuario();
    final lista = _store.eventos.value.where((e) => e.idEvento == idEvento);
    if (lista.isEmpty) throw ArgumentError('El evento ya no existe.');
    final evento = lista.first;
    final coordinador = _store
        .ministerioPorPath(evento.ministerioRef?.path)
        ?.coordinadorRef
        .path;
    PermisosModeracion.exigirModerar(
      usuario: _store.usuarioActual.value,
      miRef: miRef,
      creadoPor: evento.creadoPor,
      soyAprobador:
          _liderDeIglesia(evento) == miRef.path || coordinador == miRef.path,
    );
    await _store.esperar();
    _store.eventos.add([
      for (final e in _store.eventos.value)
        e.idEvento == idEvento
            ? DemoCopias.evento(e, estadoAprobacion: nuevo)
            : e,
    ]);
  }

  /// Aprobador de un evento = líder (Pastor/Padre) de su iglesia.
  String? _liderDeIglesia(EventoModel e) =>
      _store.iglesiaPorPath(e.iglesiaRef?.path)?.liderUidRef?.path;

  @override
  Future<void> eliminarDefinitivamente(String idEvento) async {
    _auth.requerirRefUsuario();
    PermisosModeracion.exigirAdmin(_store.usuarioActual.value);
    _store.eventos.add(
        _store.eventos.value.where((e) => e.idEvento != idEvento).toList());
  }

  // ---------- Internos ----------
  /// Públicos + los míos (incluye Pendientes), según la sesión actual.
  Stream<List<EventoModel>> _visibles() {
    return Rx.combineLatest2<List<EventoModel>, String?, List<EventoModel>>(
      _store.eventos,
      _auth.observarUid(),
      (lista, _) {
        final miPath = _auth.refUsuarioActual?.path;
        return lista
            .where((e) =>
                _esPublico(e) ||
                (_esMio(e, miPath) &&
                    e.estadoLogico == EstadoLogico.activo &&
                    e.estadoAprobacion != EstadoAprobacion.rechazado))
            .toList();
      },
    );
  }

  bool _esPublico(EventoModel e) =>
      e.estadoAprobacion == EstadoAprobacion.aprobado &&
      e.estadoLogico == EstadoLogico.activo;

  bool _esMio(EventoModel e, String? miPath) =>
      miPath != null && e.creadoPor.path == miPath;

  bool _enVentana(EventoModel e) {
    final ahora = DateTime.now();
    final fin =
        ahora.add(const Duration(days: AppConstants.ventanaEventosDias));
    return !e.fechaHoraInicio.isBefore(ahora) &&
        e.fechaHoraInicio.isBefore(fin);
  }

  List<EventoModel> _historial(
    Iterable<EventoModel> eventos, {
    DateTime? desde,
    DateTime? hasta,
  }) {
    final ahora = DateTime.now();
    final limiteInferior = DateTime(
        ahora.year, ahora.month - AppConstants.historialMaxMeses, ahora.day);
    var inicio = desde ?? limiteInferior;
    if (inicio.isBefore(limiteInferior)) inicio = limiteInferior;
    var fin = hasta ?? ahora;
    if (fin.isAfter(ahora)) fin = ahora;

    return _ordenar(
      eventos.where((e) =>
          !e.fechaHoraInicio.isBefore(inicio) &&
          e.fechaHoraInicio.isBefore(fin)),
      descendente: true,
    ).take(AppConstants.maxHistorialPorConsulta).toList();
  }

  List<EventoModel> _ordenar(Iterable<EventoModel> eventos,
      {bool descendente = false}) {
    final lista = eventos.toList()
      ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));
    return descendente ? lista.reversed.toList() : lista;
  }
}
