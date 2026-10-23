import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/evento_model.dart';
import '../../data/repositories/evento_repository.dart';

/// Estado del Bottom Sheet de una iglesia: próximos 30 días (RF-5.2) e
/// Historial/Vencidos con filtro de hasta 16 meses (RF-5.3, RF-5.4).
class EventosIglesiaViewModel extends ChangeNotifier {
  EventosIglesiaViewModel({
    required EventoRepository eventoRepository,
    required this.idIglesia,
  }) : _repo = eventoRepository {
    _sub = _repo.observarEventosDeIglesia(idIglesia).listen(
      (lista) {
        _proximos = lista;
        _cargandoProximos = false;
        _errorProximos = null;
        notifyListeners();
      },
      onError: (Object e) {
        _cargandoProximos = false;
        _errorProximos = 'No se pudieron cargar los eventos.\n($e)';
        notifyListeners();
      },
    );
  }

  final EventoRepository _repo;
  final String idIglesia;
  StreamSubscription<List<EventoModel>>? _sub;

  /// Opciones del filtro de historial (en meses).
  static const List<int> opcionesMeses = [
    1,
    3,
    6,
    12,
    AppConstants.historialMaxMeses
  ];

  List<EventoModel> _proximos = const [];
  bool _cargandoProximos = true;
  String? _errorProximos;

  List<EventoModel>? _historial;
  bool _cargandoHistorial = false;
  String? _errorHistorial;
  int _mesesHistorial = AppConstants.historialMaxMeses;

  List<EventoModel> get proximos => _proximos;
  bool get cargandoProximos => _cargandoProximos;
  String? get errorProximos => _errorProximos;

  List<EventoModel>? get historial => _historial;
  bool get cargandoHistorial => _cargandoHistorial;
  String? get errorHistorial => _errorHistorial;
  int get mesesHistorial => _mesesHistorial;

  /// Carga el historial la primera vez que se abre la pestaña.
  Future<void> asegurarHistorial() async {
    if (_historial != null || _cargandoHistorial) return;
    await cargarHistorial();
  }

  Future<void> cambiarMeses(int meses) async {
    _mesesHistorial = meses.clamp(1, AppConstants.historialMaxMeses);
    await cargarHistorial();
  }

  Future<void> cargarHistorial() async {
    _cargandoHistorial = true;
    _errorHistorial = null;
    notifyListeners();
    try {
      final ahora = DateTime.now();
      final desde =
          DateTime(ahora.year, ahora.month - _mesesHistorial, ahora.day);
      _historial =
          await _repo.obtenerHistorialDeIglesia(idIglesia, desde: desde);
    } catch (e) {
      _errorHistorial = 'No se pudo cargar el historial.\n($e)';
    } finally {
      _cargandoHistorial = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
