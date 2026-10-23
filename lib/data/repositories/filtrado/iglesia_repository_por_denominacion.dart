import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentReference, GeoPoint;

import '../../../core/constants/app_constants.dart';
import '../../models/enums.dart';
import '../../models/iglesia_model.dart';
import '../iglesia_repository.dart';
import 'resolutor_denominacion.dart';

/// Decorador de [IglesiaRepository] para las Apps de una sola denominación:
/// solo deja pasar iglesias de [denominacion] y no permite crear otras.
/// Funciona igual sobre Firebase o sobre el Modo Demo.
class IglesiaRepositoryPorDenominacion implements IglesiaRepository {
  IglesiaRepositoryPorDenominacion({
    required IglesiaRepository base,
    required this.denominacion,
    required ResolutorDenominacion resolutor,
  })  : _base = base,
        _resolutor = resolutor;

  final IglesiaRepository _base;
  final Denominacion denominacion;
  final ResolutorDenominacion _resolutor;

  List<IglesiaModel> _filtrar(List<IglesiaModel> lista) {
    _resolutor.registrarIglesias(lista);
    return lista.where((i) => i.denominacion == denominacion).toList();
  }

  @override
  DocumentReference<Map<String, dynamic>> refDe(String idIglesia) =>
      _base.refDe(idIglesia);

  @override
  Future<IglesiaModel?> obtener(String idIglesia) async {
    final iglesia = await _base.obtener(idIglesia);
    if (iglesia == null) return null;
    _resolutor.registrarIglesias([iglesia]);
    return iglesia.denominacion == denominacion ? iglesia : null;
  }

  @override
  Stream<List<IglesiaModel>> observarIglesiasDelMapa({
    String localidad = AppConstants.localidadPorDefecto,
  }) =>
      _base.observarIglesiasDelMapa(localidad: localidad).map(_filtrar);

  @override
  Stream<List<IglesiaModel>> observarMisIglesias() =>
      _base.observarMisIglesias().map(_filtrar);

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
  }) {
    if (denominacion != this.denominacion) {
      throw ArgumentError(
          'En esta app solo se registran iglesias ${this.denominacion.label}.');
    }
    return _base.crearIglesia(
      nombre: nombre,
      denominacion: denominacion,
      tipo: tipo,
      ubicacion: ubicacion,
      direccionTexto: direccionTexto,
      linkVirtual: linkVirtual,
      pais: pais,
      localidad: localidad,
      liderNombreTexto: liderNombreTexto,
      aprobadorNombreTexto: aprobadorNombreTexto,
    );
  }

  @override
  Future<void> actualizar(IglesiaModel iglesia) {
    if (iglesia.denominacion != denominacion) {
      throw ArgumentError(
          'En esta app solo se gestionan iglesias ${denominacion.label}.');
    }
    return _base.actualizar(iglesia);
  }

  @override
  Future<void> eliminar(String idIglesia) => _base.eliminar(idIglesia);

  @override
  Stream<List<IglesiaModel>> observarPendientesDeModeracion() =>
      _base.observarPendientesDeModeracion().map(_filtrar);

  @override
  Future<void> aprobar(String idIglesia) => _base.aprobar(idIglesia);

  @override
  Future<void> rechazar(String idIglesia) => _base.rechazar(idIglesia);

  @override
  Stream<List<IglesiaModel>> observarPorVerificar() => _base
      .observarPorVerificar()
      .map((l) => l.where((i) => i.denominacion == denominacion).toList());

  @override
  Future<void> confirmarDenominacion(String idIglesia) =>
      _base.confirmarDenominacion(idIglesia);

  @override
  Future<void> descartarImportada(String idIglesia) =>
      _base.descartarImportada(idIglesia);

  @override
  Future<void> eliminarDefinitivamente(String idIglesia) =>
      _base.eliminarDefinitivamente(idIglesia);
}
