import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/enums.dart';
import '../../data/models/iglesia_model.dart';
import '../../data/models/solicitud_reclamo_model.dart';
import '../../data/repositories/reclamo_repository.dart';
import '../../data/repositories/sesion_requerida_exception.dart';

/// Pantalla "Reclamar / gestionar esta iglesia": muestra el estado de mi
/// solicitud y la envía (queda Pendiente hasta que el Admin General la
/// apruebe).
class ReclamarIglesiaViewModel extends ChangeNotifier {
  ReclamarIglesiaViewModel({
    required ReclamoRepository reclamoRepository,
    required this.iglesia,
  }) : _repo = reclamoRepository {
    _sub = _repo.observarMiSolicitud(iglesia.idIglesia).listen(
      (s) {
        _solicitud = s;
        _cargando = false;
        notifyListeners();
      },
      onError: (Object e) {
        _cargando = false;
        _error = 'No se pudo leer tu solicitud.\n($e)';
        notifyListeners();
      },
    );
  }

  final ReclamoRepository _repo;
  final IglesiaModel iglesia;
  StreamSubscription<SolicitudReclamoModel?>? _sub;

  SolicitudReclamoModel? _solicitud;
  bool _cargando = true;
  bool _enviando = false;
  String? _error;

  SolicitudReclamoModel? get solicitud => _solicitud;
  bool get cargando => _cargando;
  bool get enviando => _enviando;
  String? get error => _error;

  /// Se puede enviar (o volver a enviar si la anterior fue rechazada).
  bool get puedeEnviar =>
      !_cargando &&
      (_solicitud == null || _solicitud!.estado == EstadoAprobacion.rechazado);

  /// Texto del estado de mi solicitud (null si no hay ninguna).
  String? get textoEstado {
    final s = _solicitud;
    if (s == null) return null;
    switch (s.estado) {
      case EstadoAprobacion.pendiente:
        return 'Tu solicitud está en revisión. El Administrador General te '
            'asignará la iglesia cuando la apruebe.';
      case EstadoAprobacion.aprobado:
        return 'Solicitud aprobada: ya administras esta iglesia.';
      case EstadoAprobacion.rechazado:
        return 'Tu solicitud anterior fue rechazada. Puedes enviar otra con '
            'más datos.';
    }
  }

  /// Envía la solicitud. Devuelve true si se guardó.
  Future<bool> enviar({required String cargo, String? mensaje}) async {
    if (_enviando) return false;
    _enviando = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.reclamar(iglesia: iglesia, cargo: cargo, mensaje: mensaje);
      return true;
    } on ArgumentError catch (e) {
      _error = '${e.message}';
      return false;
    } on SesionRequeridaException catch (e) {
      _error = e.toString();
      return false;
    } catch (e) {
      _error = 'No se pudo enviar la solicitud. Inténtalo de nuevo.\n($e)';
      return false;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
