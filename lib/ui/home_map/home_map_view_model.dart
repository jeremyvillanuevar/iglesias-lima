import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/app_flavor.dart';
import '../../core/config/terminologia.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/texto_busqueda.dart';
import '../../core/utils/ubicacion_dispositivo.dart';
import '../../data/models/enums.dart';
import '../../data/models/evento_model.dart';
import '../../data/models/iglesia_model.dart';
import '../../data/repositories/evento_repository.dart';
import '../../data/repositories/iglesia_repository.dart';
import '../shared/map/coordenada_mapa.dart';
import '../shared/map/marcador_mapa.dart';

/// Estado de la pantalla principal: pines, buscador y filtros (RF-5.1, RF-5.5).
class HomeMapViewModel extends ChangeNotifier {
  HomeMapViewModel({
    required IglesiaRepository iglesiaRepository,
    required EventoRepository eventoRepository,
    this.flavor = AppFlavor.porDefecto,
    UbicacionDispositivo ubicacion = const UbicacionDispositivo(),
  })  : _iglesiasRepo = iglesiaRepository,
        _eventosRepo = eventoRepository,
        _ubicacion = ubicacion {
    _suscribir();
  }

  final IglesiaRepository _iglesiasRepo;
  final EventoRepository _eventosRepo;
  final UbicacionDispositivo _ubicacion;

  /// App que se está ejecutando: en las Apps 1 a 4 no hay chips de
  /// denominación y solo se ven iglesias de esa denominación.
  final AppFlavor flavor;

  /// Vocabulario de la app (ej. tipos de evento que se ofrecen).
  Terminologia get terminologia => flavor.terminologia;

  StreamSubscription<List<IglesiaModel>>? _subIglesias;
  StreamSubscription<List<EventoModel>>? _subEventos;

  static const CoordenadaMapa centroLima =
      CoordenadaMapa(AppConstants.limaLatitud, AppConstants.limaLongitud);

  List<IglesiaModel> _iglesias = const [];
  List<EventoModel> _eventosProximos = const [];
  bool _cargandoIglesias = true;
  String? _error;

  String _texto = '';
  final Set<Denominacion> _denominaciones = {};
  String? _categoria;

  CoordenadaMapa? _miUbicacion;
  bool _buscandoUbicacion = false;

  // ---------- Getters ----------
  bool get cargando => _cargandoIglesias;
  String? get error => _error;
  String get texto => _texto;
  Set<Denominacion> get denominaciones => Set.unmodifiable(_denominaciones);
  String? get categoria => _categoria;
  CoordenadaMapa? get miUbicacion => _miUbicacion;
  bool get buscandoUbicacion => _buscandoUbicacion;
  List<String> get categorias => AppConstants.categoriasEventos;

  /// Chips de denominación a mostrar (vacío en las Apps de una sola denominación).
  List<Denominacion> get denominacionesFiltrables =>
      flavor.esDenominacionUnica ? const [] : Denominacion.values;

  bool get hayFiltros =>
      _texto.trim().isNotEmpty ||
      _denominaciones.isNotEmpty ||
      _categoria != null;

  int get totalIglesias => _iglesias.length;

  /// Iglesias que cumplen buscador + denominación + categoría.
  List<IglesiaModel> get iglesiasFiltradas {
    final porIglesia = _eventosPorIglesia();
    final lista = _iglesias.where((i) {
      // Defensa adicional: el repositorio ya filtra por la app.
      if (!flavor.admite(i.denominacion)) return false;
      if (_denominaciones.isNotEmpty &&
          !_denominaciones.contains(i.denominacion)) {
        return false;
      }
      final eventos = porIglesia[i.idIglesia] ?? const <EventoModel>[];
      if (_categoria != null &&
          !eventos.any((e) => e.categoria == _categoria)) {
        return false;
      }
      if (_texto.trim().isEmpty) return true;
      return TextoBusqueda.coincide(_texto, [
            i.nombre,
            i.direccionTexto,
            i.localidad,
            i.denominacion.label,
            i.denominacion.etiquetaCorta,
            i.liderNombreTexto,
          ]) ||
          eventos.any((e) => TextoBusqueda.coincide(
              _texto, [e.titulo, e.categoria, e.descripcion]));
    }).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  /// Pines del mapa (solo iglesias físicas con coordenadas).
  List<MarcadorMapa> get marcadores => marcadoresPara();

  /// Pines del mapa; si [esAdmin], las importadas "por verificar" se marcan
  /// de forma discreta (solo el Administrador General las distingue).
  List<MarcadorMapa> marcadoresPara({bool esAdmin = false}) => [
        for (final i in iglesiasFiltradas)
          if (i.esFisica && i.ubicacion != null)
            MarcadorMapa(
              id: i.idIglesia,
              posicion:
                  CoordenadaMapa(i.ubicacion!.latitude, i.ubicacion!.longitude),
              titulo: i.nombre,
              subtitulo: flavor.terminologia.procedenciaCortaDe(i),
              color: AppTheme.colorDenominacion(i.denominacion),
              pendiente: i.estadoAprobacion == EstadoAprobacion.pendiente,
              porVerificar: esAdmin && i.porVerificar,
            ),
      ];

  IglesiaModel? iglesiaPorId(String id) {
    for (final i in _iglesias) {
      if (i.idIglesia == id) return i;
    }
    return null;
  }

  /// Cantidad de eventos visibles de la iglesia en los próximos 30 días.
  int eventosProximosDe(String idIglesia) =>
      _eventosPorIglesia()[idIglesia]?.length ?? 0;

  // ---------- Acciones ----------
  void buscar(String texto) {
    _texto = texto;
    notifyListeners();
  }

  void alternarDenominacion(Denominacion d) {
    if (!_denominaciones.remove(d)) _denominaciones.add(d);
    notifyListeners();
  }

  void elegirCategoria(String? categoria) {
    _categoria = categoria;
    notifyListeners();
  }

  void limpiarFiltros() {
    _texto = '';
    _denominaciones.clear();
    _categoria = null;
    notifyListeners();
  }

  void reintentar() {
    _error = null;
    _cargandoIglesias = true;
    notifyListeners();
    _suscribir();
  }

  /// Devuelve la ubicación o lanza [UbicacionNoDisponible] con el motivo.
  Future<CoordenadaMapa> ubicarme() async {
    _buscandoUbicacion = true;
    notifyListeners();
    try {
      final c = await _ubicacion.obtener();
      _miUbicacion = c;
      return c;
    } on UbicacionNoDisponible {
      rethrow;
    } catch (e) {
      throw UbicacionNoDisponible('No se pudo obtener tu ubicación ($e).');
    } finally {
      _buscandoUbicacion = false;
      notifyListeners();
    }
  }

  // ---------- Internos ----------
  void _suscribir() {
    _subIglesias?.cancel();
    _subEventos?.cancel();
    _subIglesias = _iglesiasRepo.observarIglesiasDelMapa().listen(
      (lista) {
        _iglesias = lista;
        _cargandoIglesias = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _cargandoIglesias = false;
        _error =
            'No se pudieron cargar las iglesias. Revisa tu conexión.\n($e)';
        notifyListeners();
      },
    );
    _subEventos = _eventosRepo.observarProximosVisibles().listen(
      (lista) {
        _eventosProximos = lista;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Error al cargar eventos próximos: $e');
      },
    );
  }

  Map<String, List<EventoModel>> _eventosPorIglesia() {
    final mapa = <String, List<EventoModel>>{};
    for (final e in _eventosProximos) {
      final id = e.iglesiaRef?.id;
      if (id == null) continue;
      (mapa[id] ??= []).add(e);
    }
    return mapa;
  }

  @override
  void dispose() {
    _subIglesias?.cancel();
    _subEventos?.cancel();
    super.dispose();
  }
}
