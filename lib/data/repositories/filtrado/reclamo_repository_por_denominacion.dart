import '../../models/enums.dart';
import '../../models/iglesia_model.dart';
import '../../models/solicitud_reclamo_model.dart';
import '../reclamo_repository.dart';

/// Decorador de [ReclamoRepository] para las Apps de una sola denominación:
/// solo muestra y acepta reclamos de iglesias de [denominacion].
class ReclamoRepositoryPorDenominacion implements ReclamoRepository {
  ReclamoRepositoryPorDenominacion({
    required ReclamoRepository base,
    required this.denominacion,
  }) : _base = base;

  final ReclamoRepository _base;
  final Denominacion denominacion;

  @override
  Stream<SolicitudReclamoModel?> observarMiSolicitud(String idIglesia) =>
      _base.observarMiSolicitud(idIglesia);

  @override
  Future<void> reclamar({
    required IglesiaModel iglesia,
    required String cargo,
    String? mensaje,
  }) {
    if (iglesia.denominacion != denominacion) {
      throw ArgumentError(
          'En esta app solo se reclaman iglesias ${denominacion.label}.');
    }
    return _base.reclamar(iglesia: iglesia, cargo: cargo, mensaje: mensaje);
  }

  @override
  Stream<List<SolicitudReclamoModel>> observarPendientes() => _base
      .observarPendientes()
      .map((l) => l.where((s) => s.denominacion == denominacion).toList());

  @override
  Future<void> aprobar(String idSolicitud) => _base.aprobar(idSolicitud);

  @override
  Future<void> rechazar(String idSolicitud) => _base.rechazar(idSolicitud);
}
