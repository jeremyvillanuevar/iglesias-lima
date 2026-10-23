import '../../models/enums.dart';
import '../../models/evento_model.dart';
import '../../recurrencia/ocurrencia_evento.dart';
import '../evento_repository.dart';
import 'resolutor_denominacion.dart';

/// Decorador de [EventoRepository] para las Apps de una sola denominación:
/// solo deja pasar eventos cuya iglesia (o ministerio) es de [denominacion].
/// El filtrado es del lado del cliente, sobre las mismas consultas de
/// siempre, así que no hacen falta índices nuevos.
class EventoRepositoryPorDenominacion implements EventoRepository {
  EventoRepositoryPorDenominacion({
    required EventoRepository base,
    required this.denominacion,
    required ResolutorDenominacion resolutor,
  })  : _base = base,
        _resolutor = resolutor;

  final EventoRepository _base;
  final Denominacion denominacion;
  final ResolutorDenominacion _resolutor;

  Future<List<EventoModel>> _filtrar(List<EventoModel> lista) =>
      _resolutor.filtrar(lista, denominacion, _resolutor.deEvento);

  Future<void> _verificarDestino(
      String? idIglesia, String? idMinisterio) async {
    final Denominacion? destino;
    if (idIglesia != null) {
      destino = await _resolutor.deIglesia(idIglesia);
    } else if (idMinisterio != null) {
      destino = await _resolutor.deMinisterioPorId(idMinisterio);
    } else {
      destino = null;
    }
    if (destino != null && destino != denominacion) {
      throw ArgumentError(
          'En esta app solo se publican eventos ${denominacion.label}.');
    }
  }

  @override
  Future<EventoModel?> obtener(String idEvento) async {
    final e = await _base.obtener(idEvento);
    if (e == null) return null;
    return await _resolutor.deEvento(e) == denominacion ? e : null;
  }

  @override
  Stream<List<EventoModel>> observarProximos30Dias() =>
      _base.observarProximos30Dias().asyncMap(_filtrar);

  @override
  Stream<List<EventoModel>> observarProximosVisibles() =>
      _base.observarProximosVisibles().asyncMap(_filtrar);

  @override
  Stream<List<EventoModel>> observarEventosDeIglesia(String idIglesia) =>
      _base.observarEventosDeIglesia(idIglesia).asyncMap(_filtrar);

  @override
  Stream<List<EventoModel>> observarEventosDeMinisterio(String idMinisterio) =>
      _base.observarEventosDeMinisterio(idMinisterio).asyncMap(_filtrar);

  @override
  Stream<List<EventoModel>> observarMisEventos() =>
      _base.observarMisEventos().asyncMap(_filtrar);

  @override
  Future<List<EventoModel>> obtenerHistorial(
          {DateTime? desde, DateTime? hasta}) async =>
      _filtrar(await _base.obtenerHistorial(desde: desde, hasta: hasta));

  @override
  Future<List<EventoModel>> obtenerHistorialDeIglesia(
    String idIglesia, {
    DateTime? desde,
  }) async =>
      _filtrar(await _base.obtenerHistorialDeIglesia(idIglesia, desde: desde));

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
    await _verificarDestino(idIglesia, idMinisterio);
    return _base.crearEvento(
      tipoActividad: tipoActividad,
      titulo: titulo,
      categoria: categoria,
      fechaHoraInicio: fechaHoraInicio,
      fechaHoraFin: fechaHoraFin,
      descripcion: descripcion,
      idIglesia: idIglesia,
      idMinisterio: idMinisterio,
      esVirtual: esVirtual,
      linkVirtual: linkVirtual,
      imagenUrl: imagenUrl,
    );
  }

  @override
  Future<List<String>> crearEventos(
    DatosNuevoEvento datos,
    List<OcurrenciaEvento> ocurrencias,
  ) async {
    await _verificarDestino(datos.idIglesia, datos.idMinisterio);
    return _base.crearEventos(datos, ocurrencias);
  }

  @override
  Future<void> actualizar(EventoModel evento) => _base.actualizar(evento);

  @override
  Future<void> eliminar(String idEvento) => _base.eliminar(idEvento);

  @override
  Stream<List<EventoModel>> observarPendientesDeModeracion() =>
      _base.observarPendientesDeModeracion().asyncMap(_filtrar);

  @override
  Future<void> aprobar(String idEvento) => _base.aprobar(idEvento);

  @override
  Future<void> rechazar(String idEvento) => _base.rechazar(idEvento);

  @override
  Future<void> eliminarDefinitivamente(String idEvento) =>
      _base.eliminarDefinitivamente(idEvento);
}
