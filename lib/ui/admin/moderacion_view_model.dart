import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;
import 'package:flutter/foundation.dart';

import '../../core/config/terminologia.dart';
import '../../data/models/enums.dart';
import '../../data/models/evento_model.dart';
import '../../data/models/iglesia_model.dart';
import '../../data/models/ministerio_model.dart';
import '../../data/models/solicitud_reclamo_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/evento_repository.dart';
import '../../data/repositories/iglesia_repository.dart';
import '../../data/repositories/ministerio_repository.dart';
import '../../data/repositories/permiso_denegado_exception.dart';
import '../../data/repositories/permisos_moderacion.dart';
import '../../data/repositories/reclamo_repository.dart';

/// Pantalla de Moderación: Iglesias, Ministerios y Eventos Pendientes y,
/// para el Administrador General, los reclamos de iglesias.
///
/// - Administrador General: ve todo; puede Aprobar, Rechazar y Borrar
///   definitivamente.
/// - Pastor/Padre: ve lo de las iglesias que lidera; puede Aprobar y
///   Rechazar, pero nunca lo que él mismo creó.
class ModeracionViewModel extends ChangeNotifier {
  ModeracionViewModel({
    required AuthRepository authRepository,
    required IglesiaRepository iglesiaRepository,
    required MinisterioRepository ministerioRepository,
    required EventoRepository eventoRepository,
    required ReclamoRepository reclamoRepository,
    required this.terminologia,
  })  : _auth = authRepository,
        _reclamosRepo = reclamoRepository,
        _iglesiasRepo = iglesiaRepository,
        _ministeriosRepo = ministerioRepository,
        _eventosRepo = eventoRepository {
    _suscribir();
  }

  /// Vocabulario de la app (cómo se llama al líder de la iglesia).
  final Terminologia terminologia;

  final AuthRepository _auth;
  final IglesiaRepository _iglesiasRepo;
  final MinisterioRepository _ministeriosRepo;
  final EventoRepository _eventosRepo;
  final ReclamoRepository _reclamosRepo;

  final List<StreamSubscription<Object?>> _subs = [];

  UserModel? _perfil;
  bool _perfilCargado = false;

  List<IglesiaModel>? _iglesias;
  List<MinisterioModel>? _ministerios;
  List<EventoModel>? _eventos;
  List<SolicitudReclamoModel>? _reclamos;
  List<IglesiaModel>? _porVerificar;
  String _filtroPorVerificar = '';
  CriterioOsm? _criterioPorVerificar;
  String? _error;

  /// Ids con una acción en curso (para deshabilitar sus botones).
  final Set<String> _enProceso = {};

  /// Nombre de la iglesia matriz de ministerios/eventos (id → nombre).
  final Map<String, String> _nombresIglesia = {};
  final Set<String> _buscandoNombre = {};

  // ---------- Getters ----------
  bool get cargandoPerfil => !_perfilCargado;
  bool get puedeModerar => PermisosModeracion.puedeAbrirModeracion(_perfil);
  bool get esAdmin => PermisosModeracion.esAdmin(_perfil);

  /// Solo el Administrador General ve el botón de borrado definitivo.
  bool get puedeBorrarDefinitivamente => esAdmin;

  String get descripcionAlcance => esAdmin
      ? 'Administrador General: ves todo lo Pendiente y puedes borrar definitivamente.'
      : '${terminologia.tituloLider}: ves lo Pendiente de las iglesias que '
          'lideras. No puedes aprobar lo que tú mismo creaste.';

  /// Mensaje para quien abre Moderación sin permiso.
  String get mensajeSinPermiso => 'Solo el Administrador General o un '
      '${terminologia.tituloLider} pueden moderar.';

  List<IglesiaModel> get iglesias => _iglesias ?? const [];
  List<MinisterioModel> get ministerios => _ministerios ?? const [];
  List<EventoModel> get eventos => _eventos ?? const [];

  /// Reclamos Pendientes (solo los ve el Administrador General).
  List<SolicitudReclamoModel> get reclamos => _reclamos ?? const [];
  bool get cargandoReclamos => _reclamos == null && _error == null;

  /// La pestaña "Reclamos" y la importación de OpenStreetMap son solo del
  /// Administrador General.
  bool get muestraReclamos => esAdmin;

  /// Importadas de OSM con denominación "Por verificar", filtradas por
  /// [filtroPorVerificar] (nombre, dirección o distrito).
  List<IglesiaModel> get porVerificar {
    final todas = _porVerificar ?? const <IglesiaModel>[];
    final f = _normalizar(_filtroPorVerificar);
    final c = _criterioPorVerificar;
    if (f.isEmpty && c == null) return todas;
    return todas
        .where((i) =>
            (c == null || i.criterio?.grupo == c) &&
            (f.isEmpty ||
                _normalizar('${i.nombre} ${i.direccionTexto ?? ''}')
                    .contains(f)))
        .toList();
  }

  /// Total sin filtrar (para la pestaña).
  int get totalPorVerificar => _porVerificar?.length ?? 0;
  bool get cargandoPorVerificar => _porVerificar == null && _error == null;
  String get filtroPorVerificar => _filtroPorVerificar;

  /// Sub-filtro de "Por verificar": null = todas;
  /// [CriterioOsm.porNombre] = con marca de la denominación en el nombre;
  /// [CriterioOsm.sinMarcador] = sin etiqueta ni marca (revisar una a una).
  CriterioOsm? get criterioPorVerificar => _criterioPorVerificar;

  void filtrarPorVerificar(String texto) {
    _filtroPorVerificar = texto;
    notifyListeners();
  }

  void filtrarPorCriterio(CriterioOsm? criterio) {
    _criterioPorVerificar = criterio;
    notifyListeners();
  }

  /// Cuántas "Por verificar" hay con [criterio] (sin el filtro de texto).
  int totalPorVerificarCon(CriterioOsm criterio) =>
      (_porVerificar ?? const <IglesiaModel>[])
          .where((i) => i.criterio?.grupo == criterio)
          .length;

  bool get cargandoIglesias => _iglesias == null && _error == null;
  bool get cargandoMinisterios => _ministerios == null && _error == null;
  bool get cargandoEventos => _eventos == null && _error == null;
  String? get error => _error;

  bool enProceso(String id) => _enProceso.contains(id);

  /// true si lo creó el usuario actual y NO es Admin General: no puede
  /// aprobarlo ni rechazarlo (mismas reglas que firestore.rules).
  bool esPropioSinPermiso(DocumentReference creadoPor) {
    if (esAdmin) return false;
    final mio = _auth.refUsuarioActual;
    return mio != null && mio.path == creadoPor.path;
  }

  /// Nombre de la iglesia (o null mientras se busca / si no hay).
  String? nombreIglesia(DocumentReference? ref) {
    if (ref == null) return null;
    final nombre = _nombresIglesia[ref.id];
    if (nombre == null) _buscarNombre(ref.id);
    return nombre;
  }

  // ---------- Acciones ----------
  /// Cada acción devuelve null si salió bien o el mensaje de error.
  Future<String?> aprobarIglesia(String id) =>
      _ejecutar(id, () => _iglesiasRepo.aprobar(id));
  Future<String?> rechazarIglesia(String id) =>
      _ejecutar(id, () => _iglesiasRepo.rechazar(id));
  Future<String?> borrarIglesia(String id) =>
      _ejecutar(id, () => _iglesiasRepo.eliminarDefinitivamente(id));

  Future<String?> aprobarMinisterio(String id) =>
      _ejecutar(id, () => _ministeriosRepo.aprobar(id));
  Future<String?> rechazarMinisterio(String id) =>
      _ejecutar(id, () => _ministeriosRepo.rechazar(id));
  Future<String?> borrarMinisterio(String id) =>
      _ejecutar(id, () => _ministeriosRepo.eliminarDefinitivamente(id));

  Future<String?> aprobarEvento(String id) =>
      _ejecutar(id, () => _eventosRepo.aprobar(id));
  Future<String?> rechazarEvento(String id) =>
      _ejecutar(id, () => _eventosRepo.rechazar(id));
  Future<String?> borrarEvento(String id) =>
      _ejecutar(id, () => _eventosRepo.eliminarDefinitivamente(id));

  Future<String?> aprobarReclamo(String id) =>
      _ejecutar(id, () => _reclamosRepo.aprobar(id));
  Future<String?> rechazarReclamo(String id) =>
      _ejecutar(id, () => _reclamosRepo.rechazar(id));

  /// Confirmar: la iglesia sí es de la denominación (queda "Confirmada").
  Future<String?> confirmarDenominacion(String id) =>
      _ejecutar(id, () => _iglesiasRepo.confirmarDenominacion(id));

  /// Descartar: no es de la denominación; se borra (solo Admin General).
  Future<String?> descartarPorVerificar(String id) =>
      _ejecutar(id, () => _iglesiasRepo.descartarImportada(id));

  void reintentar() {
    _error = null;
    _iglesias = null;
    _ministerios = null;
    _eventos = null;
    _reclamos = null;
    _porVerificar = null;
    notifyListeners();
    _suscribir();
  }

  // ---------- Internos ----------
  Future<String?> _ejecutar(String id, Future<void> Function() accion) async {
    if (_enProceso.contains(id)) return null;
    _enProceso.add(id);
    notifyListeners();
    try {
      await accion();
      return null;
    } on PermisoDenegadoException catch (e) {
      return e.mensaje;
    } on ArgumentError catch (e) {
      return '${e.message}';
    } catch (e) {
      return 'No se pudo completar la acción. Revisa tu conexión o tus permisos.\n($e)';
    } finally {
      _enProceso.remove(id);
      notifyListeners();
    }
  }

  void _suscribir() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs
      ..clear()
      ..add(_auth.observarPerfilActual().listen((p) {
        _perfil = p;
        _perfilCargado = true;
        notifyListeners();
      }, onError: _alFallar))
      ..add(_iglesiasRepo.observarPendientesDeModeracion().listen((l) {
        _iglesias = l;
        notifyListeners();
      }, onError: _alFallar))
      ..add(_ministeriosRepo.observarPendientesDeModeracion().listen((l) {
        _ministerios = l;
        notifyListeners();
      }, onError: _alFallar))
      ..add(_eventosRepo.observarPendientesDeModeracion().listen((l) {
        _eventos = l;
        notifyListeners();
      }, onError: _alFallar))
      ..add(_reclamosRepo.observarPendientes().listen((l) {
        _reclamos = l;
        notifyListeners();
      }, onError: _alFallar))
      ..add(_iglesiasRepo.observarPorVerificar().listen((l) {
        _porVerificar = l;
        notifyListeners();
      }, onError: _alFallar));
  }

  void _alFallar(Object e) {
    _perfilCargado = true;
    _error =
        'No se pudo cargar la moderación. Revisa tu conexión o tus permisos.\n($e)';
    notifyListeners();
  }

  Future<void> _buscarNombre(String idIglesia) async {
    if (!_buscandoNombre.add(idIglesia)) return;
    try {
      final iglesia = await _iglesiasRepo.obtener(idIglesia);
      _nombresIglesia[idIglesia] = iglesia?.nombre ?? 'Iglesia no disponible';
    } catch (_) {
      _nombresIglesia[idIglesia] = 'Iglesia no disponible';
    }
    if (!_disposed) notifyListeners();
  }

  bool _disposed = false;

  static String _normalizar(String s) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    final b = StringBuffer();
    for (final c in s.toLowerCase().trim().split('')) {
      final i = conTilde.indexOf(c);
      b.write(i >= 0 ? sinTilde[i] : c);
    }
    return b.toString();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
