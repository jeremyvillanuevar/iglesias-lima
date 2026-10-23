import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter/foundation.dart';

import '../../core/config/app_flavor.dart';
import '../../core/config/terminologia.dart';
import '../../data/models/enums.dart';
import '../../data/models/iglesia_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/iglesia_repository.dart';
import '../../data/repositories/ministerio_repository.dart';
import '../../data/repositories/permiso_denegado_exception.dart';
import '../shared/map/coordenada_mapa.dart';

/// Estado del formulario "Nuevo ministerio" (RF-3.1 a RF-3.3).
///
/// - El creador queda como "Administrador de Ministerio" (coordinador).
/// - Puede estar vinculado a una iglesia matriz o ser independiente:
///   con ubicación propia en el mapa (+ país/localidad) o solo virtual.
/// - Entra como Pendiente.
/// - En las Apps 1 a 4 la denominación la fija la app.
class CrearMinisterioViewModel extends ChangeNotifier {
  CrearMinisterioViewModel({
    required MinisterioRepository ministerioRepository,
    required IglesiaRepository iglesiaRepository,
    this.flavor = AppFlavor.porDefecto,
    String? idIglesiaInicial,
  })  : _repo = ministerioRepository,
        _iglesiasRepo = iglesiaRepository,
        _idIglesia = idIglesiaInicial,
        _denominacion = flavor.denominacionFija ?? Denominacion.catolica {
    _sub = _iglesiasRepo.observarIglesiasDelMapa().listen(
      (lista) {
        _iglesias = [...lista]..sort((a, b) => a.nombre.compareTo(b.nombre));
        _cargandoIglesias = false;
        // Si la iglesia elegida ya no está disponible, se limpia.
        if (_idIglesia != null &&
            !_iglesias.any((i) => i.idIglesia == _idIglesia)) {
          _idIglesia = null;
        }
        notifyListeners();
      },
      onError: (Object e) {
        _cargandoIglesias = false;
        _error = 'No se pudieron cargar las iglesias: $e';
        notifyListeners();
      },
    );
  }

  final MinisterioRepository _repo;
  final IglesiaRepository _iglesiasRepo;
  final AppFlavor flavor;

  /// Vocabulario de la app (cómo se llama al líder de la iglesia matriz).
  Terminologia get terminologia => flavor.terminologia;
  StreamSubscription<List<IglesiaModel>>? _sub;

  List<IglesiaModel> _iglesias = const [];
  bool _cargandoIglesias = true;

  TipoUbicacionMinisterio _tipo = TipoUbicacionMinisterio.iglesia;
  String? _idIglesia;
  CoordenadaMapa? _ubicacion;
  Denominacion _denominacion;

  bool _guardando = false;
  bool _intentoGuardar = false;
  String? _error;

  // ---------- Getters ----------
  List<IglesiaModel> get iglesias => _iglesias;
  bool get cargandoIglesias => _cargandoIglesias;
  TipoUbicacionMinisterio get tipo => _tipo;
  bool get vinculadoAIglesia => _tipo == TipoUbicacionMinisterio.iglesia;
  bool get esFisico => _tipo == TipoUbicacionMinisterio.fisica;
  bool get esVirtual => _tipo == TipoUbicacionMinisterio.virtual;
  String? get idIglesia => _idIglesia;
  CoordenadaMapa? get ubicacion => _ubicacion;
  bool get guardando => _guardando;
  String? get error => _error;

  IglesiaModel? get iglesiaSeleccionada {
    for (final i in _iglesias) {
      if (i.idIglesia == _idIglesia) return i;
    }
    return null;
  }

  /// La de la iglesia matriz si está vinculado; si no, la de la app
  /// (o la elegida en la App 5).
  Denominacion get denominacion => vinculadoAIglesia
      ? (iglesiaSeleccionada?.denominacion ?? _denominacion)
      : _denominacion;

  /// No se puede cambiar: la fija la app (Apps 1 a 4) o la iglesia matriz.
  bool get denominacionBloqueada =>
      flavor.esDenominacionUnica || vinculadoAIglesia;

  String get ayudaDenominacion {
    if (flavor.esDenominacionUnica) {
      return 'En ${flavor.nombreApp} solo se registran ministerios ${denominacion.label}.';
    }
    if (vinculadoAIglesia) return 'Se toma de la iglesia matriz.';
    return 'Elige la denominación del ministerio independiente.';
  }

  String? get errorIglesia =>
      _intentoGuardar && vinculadoAIglesia && _idIglesia == null
          ? 'Elige la iglesia matriz del ministerio.'
          : null;

  String? get errorUbicacion =>
      _intentoGuardar && esFisico && _ubicacion == null
          ? 'Toca el mapa para marcar dónde se reúne el ministerio.'
          : null;

  // ---------- Acciones ----------
  void cambiarTipo(TipoUbicacionMinisterio t) {
    _tipo = t;
    notifyListeners();
  }

  void elegirIglesia(String? id) {
    _idIglesia = id;
    notifyListeners();
  }

  void elegirUbicacion(CoordenadaMapa c) {
    _ubicacion = c;
    notifyListeners();
  }

  void cambiarDenominacion(Denominacion d) {
    if (denominacionBloqueada) return;
    _denominacion = d;
    notifyListeners();
  }

  /// Valida lo que el Form no valida solo (iglesia elegida y punto del mapa).
  bool validarSelecciones() {
    _intentoGuardar = true;
    notifyListeners();
    return errorIglesia == null && errorUbicacion == null;
  }

  /// Devuelve el id del ministerio creado, o null si hubo error.
  Future<String?> guardar({
    required String nombre,
    String? linkVirtual,
    String? pais,
    String? localidad,
  }) async {
    if (!validarSelecciones()) return null;
    _guardando = true;
    _error = null;
    notifyListeners();
    try {
      return await _repo.crearMinisterio(
        nombre: nombre,
        tipoUbicacion: _tipo,
        idIglesia: vinculadoAIglesia ? _idIglesia : null,
        ubicacionPropia: esFisico && _ubicacion != null
            ? GeoPoint(_ubicacion!.latitud, _ubicacion!.longitud)
            : null,
        linkVirtual: esVirtual ? linkVirtual : null,
        denominacion: denominacion,
        pais: esFisico ? pais : null,
        localidad: esFisico ? localidad : null,
      );
    } on ArgumentError catch (e) {
      _error = '${e.message}';
      return null;
    } on SesionRequeridaException catch (e) {
      _error = e.toString();
      return null;
    } on PermisoDenegadoException catch (e) {
      _error = e.mensaje;
      return null;
    } catch (e) {
      _error = 'No se pudo guardar el ministerio. Inténtalo de nuevo.\n($e)';
      return null;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
