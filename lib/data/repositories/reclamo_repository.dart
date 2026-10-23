import '../models/iglesia_model.dart';
import '../models/solicitud_reclamo_model.dart';

/// Reclamos de iglesias "Sin administrador": un usuario pide administrarla y
/// el Administrador General aprueba o rechaza.
///
/// Implementaciones: `FirebaseReclamoRepository` y `DemoReclamoRepository`.
abstract class ReclamoRepository {
  /// Mi solicitud sobre [idIglesia] (null si no envié ninguna o no hay sesión).
  Stream<SolicitudReclamoModel?> observarMiSolicitud(String idIglesia);

  /// Envía (o reenvía, si la anterior fue Rechazada) una solicitud Pendiente.
  /// La iglesia pasa a "Reclamo pendiente", pero NO queda administrada.
  Future<void> reclamar({
    required IglesiaModel iglesia,
    required String cargo,
    String? mensaje,
  });

  /// Solicitudes Pendientes (solo el Administrador General; otros: vacío).
  Stream<List<SolicitudReclamoModel>> observarPendientes();

  /// El solicitante pasa a ser el administrador (líder) de la iglesia, que
  /// queda "Administrada". Las demás solicitudes de esa iglesia se rechazan.
  Future<void> aprobar(String idSolicitud);

  /// La solicitud queda Rechazada; si no quedan otras, la iglesia vuelve a
  /// "Sin administrador".
  Future<void> rechazar(String idSolicitud);
}
