import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter/foundation.dart';

import '../../core/config/app_flavor.dart';
import '../../core/config/terminologia.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/iglesia_repository.dart';
import '../shared/map/coordenada_mapa.dart';

/// Estado del formulario "Nueva iglesia" (RF-2.1 a RF-2.4).
class CrearIglesiaViewModel extends ChangeNotifier {
  CrearIglesiaViewModel({
    required IglesiaRepository iglesiaRepository,
    this.flavor = AppFlavor.porDefecto,
  })  : _repo = iglesiaRepository,
        _denominacion = flavor.denominacionFija ?? Denominacion.catolica;

  final IglesiaRepository _repo;

  /// En las Apps 1 a 4 la denominación viene fijada por la app.
  final AppFlavor flavor;

  /// Vocabulario de la app (ej. 'Padre' en la App 1, 'Pastor' en la App 2).
  Terminologia get terminologia => flavor.terminologia;

  Denominacion _denominacion;
  TipoUbicacion _tipo = TipoUbicacion.fisica;
  CoordenadaMapa? _ubicacion;
  bool _guardando = false;
  String? _error;
  bool _intentoGuardar = false;

  Denominacion get denominacion => _denominacion;
  bool get denominacionBloqueada => flavor.esDenominacionUnica;
  TipoUbicacion get tipo => _tipo;
  bool get esFisica => _tipo == TipoUbicacion.fisica;
  CoordenadaMapa? get ubicacion => _ubicacion;
  bool get guardando => _guardando;
  String? get error => _error;

  /// Mensaje bajo el mapa si se intentó guardar sin marcar el punto.
  String? get errorUbicacion =>
      _intentoGuardar && esFisica && _ubicacion == null
          ? 'Toca el mapa para marcar dónde está la iglesia.'
          : null;

  void cambiarDenominacion(Denominacion d) {
    if (denominacionBloqueada) return;
    _denominacion = d;
    notifyListeners();
  }

  void cambiarTipo(TipoUbicacion t) {
    _tipo = t;
    notifyListeners();
  }

  void elegirUbicacion(CoordenadaMapa c) {
    _ubicacion = c;
    notifyListeners();
  }

  /// Valida lo que el formulario no puede validar solo (el punto del mapa).
  bool validarUbicacion() {
    _intentoGuardar = true;
    notifyListeners();
    return !esFisica || _ubicacion != null;
  }

  /// Devuelve el id de la iglesia creada, o null si hubo error.
  Future<String?> guardar({
    required String nombre,
    String? direccion,
    String? linkVirtual,
    String pais = AppConstants.paisPorDefecto,
    String localidad = AppConstants.localidadPorDefecto,
    String? pastor,
    String? aprobador,
  }) async {
    if (!validarUbicacion()) return null;
    _guardando = true;
    _error = null;
    notifyListeners();
    try {
      return await _repo.crearIglesia(
        nombre: nombre,
        denominacion: _denominacion,
        tipo: _tipo,
        ubicacion: esFisica && _ubicacion != null
            ? GeoPoint(_ubicacion!.latitud, _ubicacion!.longitud)
            : null,
        direccionTexto: esFisica ? direccion : null,
        linkVirtual: esFisica ? null : linkVirtual,
        pais: pais,
        localidad: localidad,
        liderNombreTexto: pastor,
        aprobadorNombreTexto: aprobador,
      );
    } on ArgumentError catch (e) {
      _error = '${e.message}';
      return null;
    } on SesionRequeridaException catch (e) {
      _error = e.toString();
      return null;
    } catch (e) {
      _error = 'No se pudo guardar la iglesia. Inténtalo de nuevo.\n($e)';
      return null;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }
}
