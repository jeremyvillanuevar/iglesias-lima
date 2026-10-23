import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentReference, GeoPoint;

import '../../models/enums.dart';
import '../../models/ministerio_model.dart';
import '../ministerio_repository.dart';
import 'resolutor_denominacion.dart';

/// Decorador de [MinisterioRepository] para las Apps de una sola
/// denominación: solo ministerios de [denominacion]; los independientes se
/// crean con la denominación de la app.
class MinisterioRepositoryPorDenominacion implements MinisterioRepository {
  MinisterioRepositoryPorDenominacion({
    required MinisterioRepository base,
    required this.denominacion,
    required ResolutorDenominacion resolutor,
  })  : _base = base,
        _resolutor = resolutor;

  final MinisterioRepository _base;
  final Denominacion denominacion;
  final ResolutorDenominacion _resolutor;

  Future<List<MinisterioModel>> _filtrar(List<MinisterioModel> lista) =>
      _resolutor.filtrar(lista, denominacion, _resolutor.deMinisterio);

  @override
  DocumentReference<Map<String, dynamic>> refDe(String idMinisterio) =>
      _base.refDe(idMinisterio);

  @override
  Future<MinisterioModel?> obtener(String idMinisterio) async {
    final m = await _base.obtener(idMinisterio);
    if (m == null) return null;
    return await _resolutor.deMinisterio(m) == denominacion ? m : null;
  }

  @override
  Stream<List<MinisterioModel>> observarPorIglesia(String idIglesia) =>
      _base.observarPorIglesia(idIglesia).asyncMap(_filtrar);

  @override
  Stream<List<MinisterioModel>> observarMisMinisterios() =>
      _base.observarMisMinisterios().asyncMap(_filtrar);

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
    if (denominacion != null && denominacion != this.denominacion) {
      throw ArgumentError(
          'En esta app solo se registran ministerios ${this.denominacion.label}.');
    }
    if (tipoUbicacion == TipoUbicacionMinisterio.iglesia && idIglesia != null) {
      final deLaIglesia = await _resolutor.deIglesia(idIglesia);
      if (deLaIglesia != this.denominacion) {
        throw ArgumentError(
            'La iglesia matriz debe ser ${this.denominacion.label}.');
      }
    }
    return _base.crearMinisterio(
      nombre: nombre,
      tipoUbicacion: tipoUbicacion,
      idIglesia: idIglesia,
      ubicacionPropia: ubicacionPropia,
      linkVirtual: linkVirtual,
      denominacion: this.denominacion,
      pais: pais,
      localidad: localidad,
    );
  }

  @override
  Future<void> actualizar(MinisterioModel ministerio) =>
      _base.actualizar(ministerio);

  @override
  Future<void> eliminar(String idMinisterio) => _base.eliminar(idMinisterio);

  @override
  Stream<List<MinisterioModel>> observarPendientesDeModeracion() =>
      _base.observarPendientesDeModeracion().asyncMap(_filtrar);

  @override
  Future<void> aprobar(String idMinisterio) => _base.aprobar(idMinisterio);

  @override
  Future<void> rechazar(String idMinisterio) => _base.rechazar(idMinisterio);

  @override
  Future<void> eliminarDefinitivamente(String idMinisterio) =>
      _base.eliminarDefinitivamente(idMinisterio);
}
