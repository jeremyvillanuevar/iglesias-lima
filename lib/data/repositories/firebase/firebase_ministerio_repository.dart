import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/enums.dart';
import '../../models/ministerio_model.dart';
import '../../services/iglesia_service.dart';
import '../../services/ministerio_service.dart';
import '../auth_repository.dart';
import '../ministerio_repository.dart';
import '../reglas_validacion.dart';
import 'moderacion_firebase.dart';

/// Ministerios guardados en Firestore (colección `ministerios`).
class FirebaseMinisterioRepository implements MinisterioRepository {
  FirebaseMinisterioRepository({
    required MinisterioService ministerioService,
    required IglesiaService iglesiaService,
    required AuthRepository authRepository,
  })  : _service = ministerioService,
        _iglesias = iglesiaService,
        _auth = authRepository;

  final MinisterioService _service;
  final IglesiaService _iglesias;
  final AuthRepository _auth;

  @override
  DocumentReference<Map<String, dynamic>> refDe(String idMinisterio) =>
      _service.refDe(idMinisterio);

  @override
  Future<MinisterioModel?> obtener(String idMinisterio) =>
      _service.obtener(idMinisterio);

  @override
  Stream<List<MinisterioModel>> observarPorIglesia(String idIglesia) {
    return _service.streamPublicosPorIglesia(_iglesias.refDe(idIglesia));
  }

  @override
  Stream<List<MinisterioModel>> observarMisMinisterios() {
    return _auth.observarUid().switchMap((uid) {
      final ref = _auth.refUsuarioActual;
      if (uid == null || ref == null) {
        return Stream<List<MinisterioModel>>.value(const []);
      }
      return _service.streamDeCoordinador(ref);
    });
  }

  @override
  Future<String> crearMinisterio({
    required String nombre,
    required TipoUbicacionMinisterio tipoUbicacion,
    String? idIglesia,
    GeoPoint? ubicacionPropia,
    String? linkVirtual,
    Denominacion? denominacion,
    String? pais,
    String? localidad,
  }) async {
    final creadoPor = _auth.requerirRefUsuario();
    ReglasValidacion.validarMinisterio(
      nombre: nombre,
      tipoUbicacion: tipoUbicacion,
      idIglesia: idIglesia,
      tieneUbicacion: ubicacionPropia != null,
      linkVirtual: linkVirtual,
      pais: pais,
      localidad: localidad,
    );
    final vinculado = tipoUbicacion == TipoUbicacionMinisterio.iglesia;
    final esFisica = tipoUbicacion == TipoUbicacionMinisterio.fisica;
    // Si está vinculado a una iglesia, hereda su denominación.
    final matriz = vinculado ? await _iglesias.obtener(idIglesia!) : null;

    final ministerio = MinisterioModel.nuevo(
      idMinisterio: _service.nuevoId(),
      nombre: nombre.trim(),
      iglesiaRef: vinculado ? _iglesias.refDe(idIglesia!) : null,
      tipoUbicacion: tipoUbicacion,
      ubicacionPropia: tipoUbicacion == TipoUbicacionMinisterio.fisica
          ? ubicacionPropia
          : null,
      linkVirtual: tipoUbicacion == TipoUbicacionMinisterio.virtual
          ? linkVirtual!.trim()
          : null,
      denominacion: matriz?.denominacion ?? denominacion,
      pais: esFisica ? ReglasValidacion.limpio(pais) : null,
      localidad: esFisica ? ReglasValidacion.limpio(localidad) : null,
      creadoPor: creadoPor,
    );

    await _service.crear(ministerio);
    return ministerio.idMinisterio;
  }

  @override
  Future<void> actualizar(MinisterioModel ministerio) =>
      _service.actualizar(ministerio);

  @override
  Future<void> eliminar(String idMinisterio) =>
      _service.eliminarLogico(idMinisterio);

  // ---------- Moderación ----------
  @override
  Stream<List<MinisterioModel>> observarPendientesDeModeracion() {
    return ModeracionFirebase.pendientes<MinisterioModel>(
      auth: _auth,
      iglesias: _iglesias,
      todos: _service.streamPendientes,
      porIglesia: _service.streamPendientesPorIglesia,
    );
  }

  @override
  Future<void> aprobar(String idMinisterio) =>
      _moderar(idMinisterio, EstadoAprobacion.aprobado);

  @override
  Future<void> rechazar(String idMinisterio) =>
      _moderar(idMinisterio, EstadoAprobacion.rechazado);

  Future<void> _moderar(String idMinisterio, EstadoAprobacion estado) async {
    final ministerio = await _service.obtener(idMinisterio);
    if (ministerio == null) throw ArgumentError('El ministerio ya no existe.');
    await ModeracionFirebase.verificarModeracion(
        auth: _auth, creadoPor: ministerio.creadoPor);
    await _service.cambiarEstadoAprobacion(idMinisterio, estado);
  }

  @override
  Future<void> eliminarDefinitivamente(String idMinisterio) async {
    await ModeracionFirebase.exigirAdmin(_auth);
    await _service.eliminarFisico(idMinisterio);
  }
}
