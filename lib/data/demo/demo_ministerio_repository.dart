import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentReference, GeoPoint;
import 'package:rxdart/rxdart.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/enums.dart';
import '../models/ministerio_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/ministerio_repository.dart';
import '../repositories/permisos_moderacion.dart';
import '../repositories/reglas_validacion.dart';
import 'demo_copias.dart';
import 'demo_data_store.dart';

/// Ministerios en memoria (Modo Demo).
class DemoMinisterioRepository implements MinisterioRepository {
  DemoMinisterioRepository(this._store, this._auth);

  final DemoDataStore _store;
  final AuthRepository _auth;

  @override
  DocumentReference<Map<String, dynamic>> refDe(String idMinisterio) =>
      _store.ref(FirestoreCollections.ministerios, idMinisterio);

  @override
  Future<MinisterioModel?> obtener(String idMinisterio) async {
    final lista =
        _store.ministerios.value.where((m) => m.idMinisterio == idMinisterio);
    return lista.isEmpty ? null : lista.first;
  }

  @override
  Stream<List<MinisterioModel>> observarPorIglesia(String idIglesia) {
    final path = '${FirestoreCollections.iglesias}/$idIglesia';
    return _store.ministerios.map((lista) => lista
        .where((m) =>
            m.iglesiaRef?.path == path &&
            m.estadoAprobacion == EstadoAprobacion.aprobado &&
            m.estadoLogico == EstadoLogico.activo)
        .toList());
  }

  @override
  Stream<List<MinisterioModel>> observarMisMinisterios() {
    return Rx.combineLatest2<List<MinisterioModel>, String?,
        List<MinisterioModel>>(
      _store.ministerios,
      _auth.observarUid(),
      (lista, uid) {
        final miPath = _auth.refUsuarioActual?.path;
        if (uid == null || miPath == null) return const [];
        return lista
            .where((m) =>
                m.coordinadorRef.path == miPath &&
                m.estadoLogico == EstadoLogico.activo)
            .toList();
      },
    );
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
    await _store.esperar();
    // Si está vinculado a una iglesia, hereda su denominación.
    final matriz = idIglesia == null
        ? null
        : _store.iglesiaPorPath('${FirestoreCollections.iglesias}/$idIglesia');
    final esFisica = tipoUbicacion == TipoUbicacionMinisterio.fisica;

    final nuevo = MinisterioModel.nuevo(
      idMinisterio: _store.nuevoId('demo-ministerio'),
      nombre: nombre.trim(),
      iglesiaRef:
          tipoUbicacion != TipoUbicacionMinisterio.iglesia || idIglesia == null
              ? null
              : _store.ref(FirestoreCollections.iglesias, idIglesia),
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
    _store.ministerios.add([..._store.ministerios.value, nuevo]);
    return nuevo.idMinisterio;
  }

  @override
  Future<void> actualizar(MinisterioModel ministerio) async {
    _auth.requerirRefUsuario();
    _store.ministerios.add([
      for (final m in _store.ministerios.value)
        m.idMinisterio == ministerio.idMinisterio ? ministerio : m,
    ]);
  }

  @override
  Future<void> eliminar(String idMinisterio) async {
    _auth.requerirRefUsuario();
    _store.ministerios.add([
      for (final m in _store.ministerios.value)
        m.idMinisterio == idMinisterio
            ? DemoCopias.ministerio(m, estadoLogico: EstadoLogico.eliminado)
            : m,
    ]);
  }

  // ---------- Moderación ----------
  @override
  Stream<List<MinisterioModel>> observarPendientesDeModeracion() {
    return Rx.combineLatest3(
      _store.ministerios,
      _store.iglesias,
      _store.usuarioActual,
      (List<MinisterioModel> lista, _, usuario) {
        if (!PermisosModeracion.puedeAbrirModeracion(usuario)) {
          return const <MinisterioModel>[];
        }
        final esAdmin = PermisosModeracion.esAdmin(usuario);
        final miPath = _auth.refUsuarioActual?.path;
        return lista
            .where((m) =>
                m.estadoAprobacion == EstadoAprobacion.pendiente &&
                m.estadoLogico == EstadoLogico.activo &&
                (esAdmin || _liderDeMatriz(m) == miPath))
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
      },
    );
  }

  @override
  Future<void> aprobar(String idMinisterio) =>
      _moderar(idMinisterio, EstadoAprobacion.aprobado);

  @override
  Future<void> rechazar(String idMinisterio) =>
      _moderar(idMinisterio, EstadoAprobacion.rechazado);

  Future<void> _moderar(String idMinisterio, EstadoAprobacion nuevo) async {
    final miRef = _auth.requerirRefUsuario();
    final ministerio = _store
        .ministerioPorPath('${FirestoreCollections.ministerios}/$idMinisterio');
    if (ministerio == null) throw ArgumentError('El ministerio ya no existe.');
    PermisosModeracion.exigirModerar(
      usuario: _store.usuarioActual.value,
      miRef: miRef,
      creadoPor: ministerio.creadoPor,
      soyAprobador: _liderDeMatriz(ministerio) == miRef.path,
    );
    await _store.esperar();
    _store.ministerios.add([
      for (final m in _store.ministerios.value)
        m.idMinisterio == idMinisterio
            ? DemoCopias.ministerio(m, estadoAprobacion: nuevo)
            : m,
    ]);
  }

  /// Aprobador de un ministerio = líder de su iglesia matriz (si tiene).
  String? _liderDeMatriz(MinisterioModel m) =>
      _store.iglesiaPorPath(m.iglesiaRef?.path)?.liderUidRef?.path;

  @override
  Future<void> eliminarDefinitivamente(String idMinisterio) async {
    _auth.requerirRefUsuario();
    PermisosModeracion.exigirAdmin(_store.usuarioActual.value);
    _store.ministerios.add(_store.ministerios.value
        .where((m) => m.idMinisterio != idMinisterio)
        .toList());
  }
}
