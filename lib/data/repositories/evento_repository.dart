import '../models/enums.dart';
import '../models/evento_model.dart';
import '../recurrencia/ocurrencia_evento.dart';
import 'datos_nuevo_evento.dart';

export 'datos_nuevo_evento.dart';

/// Contrato de eventos que usan los ViewModels.
///
/// Implementaciones: `FirebaseEventoRepository` y `DemoEventoRepository`.
abstract class EventoRepository {
  Future<EventoModel?> obtener(String idEvento);

  /// Lista general: eventos públicos de los próximos 30 días (RF-5.2).
  Stream<List<EventoModel>> observarProximos30Dias();

  /// Próximos 30 días visibles para mí: públicos + mis Pendientes (RF-4.5).
  /// Se usa para los filtros de categoría y el buscador del mapa.
  Stream<List<EventoModel>> observarProximosVisibles();

  /// Bottom Sheet de una iglesia (RF-5.1): públicos de los próximos 30 días
  /// + mis Pendientes en esa misma iglesia.
  Stream<List<EventoModel>> observarEventosDeIglesia(String idIglesia);

  /// Eventos públicos de un ministerio en los próximos 30 días.
  Stream<List<EventoModel>> observarEventosDeMinisterio(String idMinisterio);

  /// Todos los eventos que creé (Pendientes y Aprobados).
  Stream<List<EventoModel>> observarMisEventos();

  /// Historial general (RF-5.3 y RF-5.4), máximo 16 meses.
  Future<List<EventoModel>> obtenerHistorial(
      {DateTime? desde, DateTime? hasta});

  /// Historial/Vencidos de una iglesia, máximo 16 meses (RF-5.4).
  Future<List<EventoModel>> obtenerHistorialDeIglesia(
    String idIglesia, {
    DateTime? desde,
  });

  /// Crea un evento Pendiente (RF-4.5). Devuelve su id.
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
  });

  /// Crea un documento por cada ocurrencia (recurrencia y turnos, RF-4.4),
  /// todos Pendientes. Devuelve los ids creados.
  Future<List<String>> crearEventos(
    DatosNuevoEvento datos,
    List<OcurrenciaEvento> ocurrencias,
  );

  Future<void> actualizar(EventoModel evento);

  /// Borrado lógico (RF-4.6).
  Future<void> eliminar(String idEvento);

  // ---------- Moderación (pantalla de Administración) ----------
  /// Pendientes que el usuario actual puede moderar: el Administrador General
  /// ve todos; un Pastor/Padre solo los de las iglesias que lidera.
  /// Sin sesión o sin rol de moderación: lista vacía.
  Stream<List<EventoModel>> observarPendientesDeModeracion();

  /// Pasa a Aprobado (público). Lanza `PermisoDenegadoException` si no corresponde.
  Future<void> aprobar(String idEvento);

  /// Pasa a Rechazado (deja de estar pendiente y nunca se publica).
  Future<void> rechazar(String idEvento);

  /// Borrado físico: solo para el Administrador General.
  Future<void> eliminarDefinitivamente(String idEvento);
}
