import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentReference, GeoPoint;
import 'package:rxdart/rxdart.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_collections.dart';
import '../models/descarte_osm.dart';
import '../models/enums.dart';
import '../models/iglesia_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/iglesia_repository.dart';
import '../repositories/permisos_moderacion.dart';
import '../repositories/reglas_validacion.dart';
import 'demo_copias.dart';
import 'demo_data_store.dart';

/// Iglesias en memoria (Modo Demo). Aplica las mismas reglas de visibilidad
/// que firestore.rules: públicas = Aprobado + Activo; Pendientes solo para su
/// creador, su líder (aprobador) o el Admin General.
class DemoIglesiaRepository implements IglesiaRepository {
  DemoIglesiaRepository(this._store, this._auth);

  final DemoDataStore _store;
  final AuthRepository _auth;

  @override
  DocumentReference<Map<String, dynamic>> refDe(String idIglesia) =>
      _store.ref(FirestoreCollections.iglesias, idIglesia);

  @override
  Future<IglesiaModel?> obtener(String idIglesia) async {
    final lista = _store.iglesias.value.where((i) => i.idIglesia == idIglesia);
    if (lista.isEmpty) return null;
    final iglesia = lista.first;
    return _puedoVer(iglesia, _auth.refUsuarioActual?.path) ? iglesia : null;
  }

  @override
  Stream<List<IglesiaModel>> observarIglesiasDelMapa({
    String localidad = AppConstants.localidadPorDefecto,
  }) {
    return Rx.combineLatest2<List<IglesiaModel>, String?, List<IglesiaModel>>(
      _store.iglesias,
      _auth.observarUid(),
      (iglesias, _) {
        final miPath = _auth.refUsuarioActual?.path;
        return iglesias.where((i) {
          if (i.estadoLogico != EstadoLogico.activo) return false;
          if (i.estadoAprobacion == EstadoAprobacion.rechazado) return false;
          if (miPath != null &&
              (i.creadoPor.path == miPath || i.liderUidRef?.path == miPath)) {
            return true;
          }
          return i.esPublica && i.localidad == localidad;
        }).toList();
      },
    );
  }

  @override
  Stream<List<IglesiaModel>> observarMisIglesias() {
    return Rx.combineLatest2<List<IglesiaModel>, String?, List<IglesiaModel>>(
      _store.iglesias,
      _auth.observarUid(),
      (iglesias, uid) {
        final miPath = _auth.refUsuarioActual?.path;
        if (uid == null || miPath == null) return const [];
        return iglesias
            .where((i) =>
                i.creadoPor.path == miPath &&
                i.estadoLogico == EstadoLogico.activo)
            .toList();
      },
    );
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
    await _store.esperar();

    final nueva = IglesiaModel.nueva(
      idIglesia: _store.nuevoId('demo-iglesia'),
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
    _store.iglesias.add([..._store.iglesias.value, nueva]);
    return nueva.idIglesia;
  }

  @override
  Future<void> actualizar(IglesiaModel iglesia) async {
    _auth.requerirRefUsuario();
    await _store.esperar();
    _store.iglesias.add([
      for (final i in _store.iglesias.value)
        // Los datos de administración no se editan aquí (igual que en Firebase).
        i.idIglesia == iglesia.idIglesia
            ? DemoCopias.iglesia(iglesia,
                estadoAdministracion: i.estadoAdministracion)
            : i,
    ]);
  }

  @override
  Future<void> eliminar(String idIglesia) async {
    _auth.requerirRefUsuario();
    _store.iglesias.add([
      for (final i in _store.iglesias.value)
        i.idIglesia == idIglesia
            ? DemoCopias.iglesia(i, estadoLogico: EstadoLogico.eliminado)
            : i,
    ]);
  }

  // ---------- Moderación ----------
  @override
  Stream<List<IglesiaModel>> observarPendientesDeModeracion() {
    return Rx.combineLatest2(
      _store.iglesias,
      _store.usuarioActual,
      (List<IglesiaModel> iglesias, usuario) {
        if (!PermisosModeracion.puedeAbrirModeracion(usuario)) {
          return const <IglesiaModel>[];
        }
        final esAdmin = PermisosModeracion.esAdmin(usuario);
        final miPath = _auth.refUsuarioActual?.path;
        return iglesias
            .where((i) =>
                i.estadoAprobacion == EstadoAprobacion.pendiente &&
                i.estadoLogico == EstadoLogico.activo &&
                (esAdmin || i.liderUidRef?.path == miPath))
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
      },
    );
  }

  @override
  Future<void> aprobar(String idIglesia) =>
      _moderar(idIglesia, EstadoAprobacion.aprobado);

  @override
  Future<void> rechazar(String idIglesia) =>
      _moderar(idIglesia, EstadoAprobacion.rechazado);

  Future<void> _moderar(String idIglesia, EstadoAprobacion nuevo) async {
    final miRef = _auth.requerirRefUsuario();
    final iglesia =
        _store.iglesiaPorPath('${FirestoreCollections.iglesias}/$idIglesia');
    if (iglesia == null) throw ArgumentError('La iglesia ya no existe.');
    PermisosModeracion.exigirModerar(
      usuario: _store.usuarioActual.value,
      miRef: miRef,
      creadoPor: iglesia.creadoPor,
      soyAprobador: iglesia.liderUidRef?.path == miRef.path,
    );
    await _store.esperar();
    _store.iglesias.add([
      for (final i in _store.iglesias.value)
        i.idIglesia == idIglesia
            ? DemoCopias.iglesia(i, estadoAprobacion: nuevo)
            : i,
    ]);
  }

  @override
  Stream<List<IglesiaModel>> observarPorVerificar() {
    return Rx.combineLatest2(
      _store.iglesias,
      _store.usuarioActual,
      (List<IglesiaModel> iglesias, usuario) {
        if (!PermisosModeracion.esAdmin(usuario)) {
          return const <IglesiaModel>[];
        }
        return iglesias
            .where(
                (i) => i.porVerificar && i.estadoLogico == EstadoLogico.activo)
            .toList()
          ..sort((a, b) =>
              a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      },
    );
  }

  @override
  Future<void> confirmarDenominacion(String idIglesia) async {
    _auth.requerirRefUsuario();
    PermisosModeracion.exigirAdmin(_store.usuarioActual.value);
    final i = _store.iglesiaPorPath('iglesias/$idIglesia');
    if (i == null) throw ArgumentError('La iglesia ya no existe.');
    _store.reemplazarIglesia(DemoCopias.iglesia(i,
        verificacionDenominacion: VerificacionDenominacion.confirmadaOsm));
  }

  @override
  Future<void> descartarImportada(String idIglesia) async {
    _auth.requerirRefUsuario();
    PermisosModeracion.exigirAdmin(_store.usuarioActual.value);
    final i = _store.iglesiaPorPath('iglesias/$idIglesia');
    if (i == null) throw ArgumentError('La iglesia ya no existe.');
    if (i.origen != OrigenIglesia.osm) {
      throw ArgumentError('Solo se descartan iglesias importadas.');
    }
    _store.osmDescartadas
        .add(DescarteOsm.idDocumento(i.denominacion, idIglesia));
    _store.iglesias.add(
      _store.iglesias.value.where((x) => x.idIglesia != idIglesia).toList(),
    );
  }

  @override
  Future<void> eliminarDefinitivamente(String idIglesia) async {
    _auth.requerirRefUsuario();
    PermisosModeracion.exigirAdmin(_store.usuarioActual.value);
    _store.iglesias.add(
      _store.iglesias.value.where((i) => i.idIglesia != idIglesia).toList(),
    );
  }

  bool _puedoVer(IglesiaModel i, String? miPath) =>
      i.esPublica ||
      PermisosModeracion.esAdmin(_store.usuarioActual.value) ||
      (miPath != null &&
          (i.creadoPor.path == miPath || i.liderUidRef?.path == miPath));
}
