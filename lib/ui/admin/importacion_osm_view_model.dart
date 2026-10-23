import 'package:flutter/foundation.dart';

import '../../core/config/fuente_importacion_osm.dart';
import '../../data/importacion/resultado_importacion.dart';
import '../../data/repositories/importacion_iglesias_repository.dart';
import '../../data/repositories/permiso_denegado_exception.dart';

/// "Importar iglesias de OpenStreetMap" (solo Admin General): recorre los
/// archivos de esta app y muestra el avance y el resultado.
class ImportacionOsmViewModel extends ChangeNotifier {
  ImportacionOsmViewModel({
    required ImportacionIglesiasRepository importacionRepository,
    required this.fuentes,
  }) : _repo = importacionRepository;

  final ImportacionIglesiasRepository _repo;

  /// Archivos que se importan (los de la app, ver AppFlavor).
  final List<FuenteImportacionOsm> fuentes;

  bool _importando = false;
  int _procesadas = 0;
  int _total = 0;
  ResultadoImportacion? _resultado;
  String? _error;
  bool _disposed = false;

  bool get importando => _importando;
  int get procesadas => _procesadas;
  int get total => _total;
  ResultadoImportacion? get resultado => _resultado;
  String? get error => _error;
  bool get hayFuentes => fuentes.isNotEmpty;

  /// 0..1, o null si aún no se sabe el total.
  double? get progreso => _total == 0 ? null : _procesadas / _total;

  String get descripcion => hayFuentes
      ? 'Se agregarán al mapa, ya aprobadas y "Sin administrador", las '
          'iglesias de: ${fuentes.map((f) => f.area).toSet().join(', ')}. '
          'Las que ya se importaron no se duplican.'
      : 'Esta app aún no trae archivos de OpenStreetMap para importar.';

  Future<void> importar() async {
    if (_importando || !hayFuentes) return;
    _importando = true;
    _error = null;
    _resultado = null;
    _procesadas = 0;
    _total = 0;
    _avisar();
    try {
      ResultadoImportacion? acumulado;
      var base = 0;
      for (final fuente in fuentes) {
        final r = await _repo.importarDesdeOsm(
          fuente,
          alProgresar: (hechas, total) {
            _procesadas = base + hechas;
            _total = base + total;
            _avisar();
          },
        );
        base += r.total;
        acumulado = acumulado == null ? r : acumulado.sumar(r);
      }
      _resultado = acumulado;
    } on PermisoDenegadoException catch (e) {
      _error = e.mensaje;
    } on ArgumentError catch (e) {
      _error = '${e.message}';
    } catch (e) {
      _error = 'No se pudo completar la importación. Revisa tu conexión y '
          'vuelve a intentarlo (lo ya importado no se repite).\n($e)';
    } finally {
      _importando = false;
      _avisar();
    }
  }

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
