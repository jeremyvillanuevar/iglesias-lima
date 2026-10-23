import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/enums.dart';
import '../../models/iglesia_model.dart';
import '../../services/iglesia_service.dart';
import '../auth_repository.dart';
import '../iglesia_repository.dart';
import '../permisos_moderacion.dart';
import '../reglas_validacion.dart';
import 'moderacion_firebase.dart';

/// Iglesias guardadas en Firestore (colección `iglesias`).
class FirebaseIglesiaRepository implements IglesiaRepository {
  FirebaseIglesiaRepository({
    required IglesiaService iglesiaService,
    required AuthRepository authRepository,
  })  : _service = iglesiaService,
        _auth = authRepository;

  final IglesiaService _service;
  final AuthRepository _auth;

  @override
  DocumentReference<Map<String, dynamic>> refDe(String idIglesia) =>
      _service.refDe(idIglesia);

  @override
  Future<IglesiaModel?> obtener(String idIglesia) =>
      _service.obtener(idIglesia);

  /// Se actualiza solo cuando el usuario inicia o cierra sesión.
  @override
  Stream<List<IglesiaModel>> observarIglesiasDelMapa({
    String localidad = AppConstants.localidadPorDefecto,
  }) {
    return _auth.observarUid().switchMap((uid) {
      final publicas = _service.streamPublicas(localidad: localidad);
      final ref = _auth.refUsuarioActual;
      if (uid == null || ref == null) return publicas;

      final mias = _service.streamDeCreador(ref);
      return Rx.combineLatest2<List<IglesiaModel>, List<IglesiaModel>,
          List<IglesiaModel>>(publicas, mias, _unirSinDuplicados);
    });
  }

  @override
  Stream<List<IglesiaModel>> observarMisIglesias() {
    return _auth.observarUid().switchMap((uid) {
      final ref = _auth.refUsuarioActual;
      if (uid == null || ref == null) {
        return Stream<List<IglesiaModel>>.value(const []);
      }
      return _service.streamDeCreador(ref);
    });
  }

  @override
  Future<String> crearIglesia({
    required String nombre,
    required Denominacion denominacion,
    required TipoUbicacion tipo,
    GeoPoint? ubicacion,
    String? direccionTexto,
    String? linkVirtual,
    String pais = AppConstants.paisPorDefecto,
    String localidad = AppConstants.localidadPorDefecto,
    String? liderNombreTexto,
    String? aprobadorNombreTexto,
  }) async {
    final creadoPor = _auth.requerirRefUsuario();
    ReglasValidacion.validarIglesia(
      nombre: nombre,
      tipo: tipo,
      tieneUbicacion: ubicacion != null,
      linkVirtual: linkVirtual,
      pais: pais,
      localidad: localidad,
    );

    final iglesia = IglesiaModel.nueva(
      idIglesia: _service.nuevoId(),
      nombre: nombre.trim(),
      denominacion: denominacion,
      tipo: tipo,
      ubicacion: ubicacion,
      direccionTexto: ReglasValidacion.limpio(direccionTexto),
      linkVirtual: ReglasValidacion.limpio(linkVirtual),
      pais: pais.trim(),
      localidad: localidad.trim(),
      liderNombreTexto: ReglasValidacion.limpio(liderNombreTexto),
      aprobadorNombreTexto: ReglasValidacion.limpio(aprobadorNombreTexto),
      creadoPor: creadoPor,
    );

    await _service.crear(iglesia);
    return iglesia.idIglesia;
  }

  @override
  Future<void> actualizar(IglesiaModel iglesia) => _service.actualizar(iglesia);

  @override
  Future<void> eliminar(String idIglesia) => _service.eliminarLogico(idIglesia);

  // ---------- Moderación ----------
  @override
  Stream<List<IglesiaModel>> observarPendientesDeModeracion() {
    return _auth.observarPerfilActual().switchMap((perfil) {
      final miRef = _auth.refUsuarioActual;
      if (!PermisosModeracion.puedeAbrirModeracion(perfil) || miRef == null) {
        return Stream<List<IglesiaModel>>.value(const []);
      }
      if (PermisosModeracion.esAdmin(perfil)) {
        return _service.streamPendientes();
      }
      // Pastor/Padre: las Pendientes donde él figura como líder (aprobador).
      return _service.streamPendientesDeLider(miRef);
    });
  }

  @override
  Future<void> aprobar(String idIglesia) =>
      _moderar(idIglesia, EstadoAprobacion.aprobado);

  @override
  Future<void> rechazar(String idIglesia) =>
      _moderar(idIglesia, EstadoAprobacion.rechazado);

  Future<void> _moderar(String idIglesia, EstadoAprobacion estado) async {
    final iglesia = await _service.obtener(idIglesia);
    if (iglesia == null) throw ArgumentError('La iglesia ya no existe.');
    await ModeracionFirebase.verificarModeracion(
        auth: _auth, creadoPor: iglesia.creadoPor);
    await _service.cambiarEstadoAprobacion(idIglesia, estado);
  }

  @override
  Stream<List<IglesiaModel>> observarPorVerificar() {
    return _auth.observarPerfilActual().switchMap((perfil) {
      if (!PermisosModeracion.esAdmin(perfil)) {
        return Stream<List<IglesiaModel>>.value(const []);
      }
      return _service.streamPorVerificar().map((l) => l
        ..sort((a, b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase())));
    });
  }

  @override
  Future<void> confirmarDenominacion(String idIglesia) async {
    await ModeracionFirebase.exigirAdmin(_auth);
    await _service.confirmarDenominacion(idIglesia);
  }

  @override
  Future<void> descartarImportada(String idIglesia) async {
    await ModeracionFirebase.exigirAdmin(_auth);
    final iglesia = await _service.obtener(idIglesia);
    if (iglesia == null) throw ArgumentError('La iglesia ya no existe.');
    if (iglesia.origen != OrigenIglesia.osm) {
      throw ArgumentError('Solo se descartan iglesias importadas.');
    }
    await _service.descartarImportada(
      idIglesia: idIglesia,
      osmId: iglesia.osmId,
      denominacion: iglesia.denominacion,
      descartadaPor: _auth.requerirRefUsuario(),
    );
  }

  @override
  Future<void> eliminarDefinitivamente(String idIglesia) async {
    await ModeracionFirebase.exigirAdmin(_auth);
    await _service.eliminarFisico(idIglesia);
  }

  // ---------- Internos ----------
  List<IglesiaModel> _unirSinDuplicados(
    List<IglesiaModel> publicas,
    List<IglesiaModel> mias,
  ) {
    final porId = <String, IglesiaModel>{
      for (final i in publicas) i.idIglesia: i,
      for (final i in mias) i.idIglesia: i,
    };
    return porId.values.toList();
  }
}
