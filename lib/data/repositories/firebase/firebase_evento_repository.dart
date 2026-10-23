import 'package:rxdart/rxdart.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/enums.dart';
import '../../models/evento_model.dart';
import '../../recurrencia/ocurrencia_evento.dart';
import '../../services/evento_service.dart';
import '../../services/iglesia_service.dart';
import '../../services/ministerio_service.dart';
import '../auth_repository.dart';
import '../evento_repository.dart';
import '../reglas_validacion.dart';
import 'moderacion_firebase.dart';

/// Eventos guardados en Firestore (colección `eventos`).
class FirebaseEventoRepository implements EventoRepository {
  FirebaseEventoRepository({
    required EventoService eventoService,
    required IglesiaService iglesiaService,
    required MinisterioService ministerioService,
    required AuthRepository authRepository,
  })  : _service = eventoService,
        _iglesias = iglesiaService,
        _ministerios = ministerioService,
        _auth = authRepository;

  final EventoService _service;
  final IglesiaService _iglesias;
  final MinisterioService _ministerios;
  final AuthRepository _auth;

  @override
  Future<EventoModel?> obtener(String idEvento) => _service.obtener(idEvento);

  @override
  Stream<List<EventoModel>> observarProximos30Dias() {
    return _service.streamProximos30Dias();
  }

  @override
  Stream<List<EventoModel>> observarProximosVisibles() {
    return _auth.observarUid().switchMap((uid) {
      final publicos = _service.streamProximos30Dias();
      final miRef = _auth.refUsuarioActual;
      if (uid == null || miRef == null) return publicos;

      final misPendientes = _service.streamDeCreador(miRef).map(
            (eventos) => eventos
                .where((e) =>
                    e.estadoAprobacion == EstadoAprobacion.pendiente &&
                    _estaEnVentana(e))
                .toList(),
          );
      return Rx.combineLatest2<List<EventoModel>, List<EventoModel>,
          List<EventoModel>>(publicos, misPendientes, _unirYOrdenar);
    });
  }

  @override
  Stream<List<EventoModel>> observarEventosDeIglesia(String idIglesia) {
    final iglesiaRef = _iglesias.refDe(idIglesia);

    return _auth.observarUid().switchMap((uid) {
      final publicos = _service.streamProximosPorIglesia(iglesiaRef);
      final miRef = _auth.refUsuarioActual;
      if (uid == null || miRef == null) return publicos;

      final misPendientes = _service.streamDeCreador(miRef).map(
            (eventos) => eventos
                .where((e) =>
                    e.iglesiaRef?.path == iglesiaRef.path &&
                    e.estadoAprobacion == EstadoAprobacion.pendiente &&
                    _estaEnVentana(e))
                .toList(),
          );

      return Rx.combineLatest2<List<EventoModel>, List<EventoModel>,
          List<EventoModel>>(publicos, misPendientes, _unirYOrdenar);
    });
  }

  @override
  Stream<List<EventoModel>> observarEventosDeMinisterio(String idMinisterio) {
    return _service
        .streamProximosPorMinisterio(_ministerios.refDe(idMinisterio));
  }

  @override
  Stream<List<EventoModel>> observarMisEventos() {
    return _auth.observarUid().switchMap((uid) {
      final ref = _auth.refUsuarioActual;
      if (uid == null || ref == null) {
        return Stream<List<EventoModel>>.value(const []);
      }
      return _service.streamDeCreador(ref);
    });
  }

  @override
  Future<List<EventoModel>> obtenerHistorial(
      {DateTime? desde, DateTime? hasta}) {
    return _service.obtenerHistorial(desde: desde, hasta: hasta);
  }

  @override
  Future<List<EventoModel>> obtenerHistorialDeIglesia(
    String idIglesia, {
    DateTime? desde,
  }) {
    return _service.obtenerHistorialPorIglesia(
      _iglesias.refDe(idIglesia),
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

    final eventos = [
      for (final o in ocurrencias)
        EventoModel.nuevo(
          idEvento: _service.nuevoId(),
          tipoActividad: datos.tipoActividad,
          titulo: datos.titulo.trim(),
          categoria: datos.categoria.trim(),
          descripcion: ReglasValidacion.limpio(datos.descripcion),
          iglesiaRef: datos.idIglesia == null
              ? null
              : _iglesias.refDe(datos.idIglesia!),
          ministerioRef: datos.idMinisterio == null
              ? null
              : _ministerios.refDe(datos.idMinisterio!),
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
    ];

    if (eventos.length == 1) {
      await _service.crear(eventos.first);
    } else {
      await _service.crearVarios(eventos); // un solo batch (todo o nada)
    }
    return eventos.map((e) => e.idEvento).toList();
  }

  @override
  Future<void> actualizar(EventoModel evento) => _service.actualizar(evento);

  @override
  Future<void> eliminar(String idEvento) => _service.eliminarLogico(idEvento);

  // ---------- Moderación ----------
  @override
  Stream<List<EventoModel>> observarPendientesDeModeracion() {
    return ModeracionFirebase.pendientes<EventoModel>(
      auth: _auth,
      iglesias: _iglesias,
      todos: _service.streamPendientes,
      porIglesia: _service.streamPendientesPorIglesia,
    ).map((lista) =>
        lista..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio)));
  }

  @override
  Future<void> aprobar(String idEvento) =>
      _moderar(idEvento, EstadoAprobacion.aprobado);

  @override
  Future<void> rechazar(String idEvento) =>
      _moderar(idEvento, EstadoAprobacion.rechazado);

  Future<void> _moderar(String idEvento, EstadoAprobacion estado) async {
    final evento = await _service.obtener(idEvento);
    if (evento == null) throw ArgumentError('El evento ya no existe.');
    await ModeracionFirebase.verificarModeracion(
        auth: _auth, creadoPor: evento.creadoPor);
    await _service.cambiarEstadoAprobacion(idEvento, estado);
  }

  @override
  Future<void> eliminarDefinitivamente(String idEvento) async {
    await ModeracionFirebase.exigirAdmin(_auth);
    await _service.eliminarFisico(idEvento);
  }

  // ---------- Internos ----------
  bool _estaEnVentana(EventoModel e) {
    final ahora = DateTime.now();
    final fin =
        ahora.add(const Duration(days: AppConstants.ventanaEventosDias));
    return !e.fechaHoraInicio.isBefore(ahora) &&
        e.fechaHoraInicio.isBefore(fin);
  }

  List<EventoModel> _unirYOrdenar(
    List<EventoModel> publicos,
    List<EventoModel> mios,
  ) {
    final porId = <String, EventoModel>{
      for (final e in publicos) e.idEvento: e,
      for (final e in mios) e.idEvento: e,
    };
    return porId.values.toList()
      ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));
  }
}
