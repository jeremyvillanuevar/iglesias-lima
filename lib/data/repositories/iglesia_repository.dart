import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentReference, GeoPoint;

import '../../core/constants/app_constants.dart';
import '../models/enums.dart';
import '../models/iglesia_model.dart';

/// Contrato de iglesias que usan los ViewModels.
///
/// Implementaciones: `FirebaseIglesiaRepository` y `DemoIglesiaRepository`.
abstract class IglesiaRepository {
  DocumentReference<Map<String, dynamic>> refDe(String idIglesia);

  Future<IglesiaModel?> obtener(String idIglesia);

  /// Pines del mapa: iglesias públicas + mis iglesias Pendientes (RF-2.4).
  Stream<List<IglesiaModel>> observarIglesiasDelMapa({
    String localidad = AppConstants.localidadPorDefecto,
  });

  /// Iglesias que creé (incluye Pendientes).
  Stream<List<IglesiaModel>> observarMisIglesias();

  /// Crea una iglesia en estado Pendiente e Informada. Devuelve su id.
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
  });

  Future<void> actualizar(IglesiaModel iglesia);

  /// Borrado lógico (RF-2.5).
  Future<void> eliminar(String idIglesia);

  // ---------- Moderación (pantalla de Administración) ----------
  /// Pendientes que el usuario actual puede moderar: el Administrador General
  /// ve todos; un Pastor/Padre solo los de las iglesias que lidera.
  /// Sin sesión o sin rol de moderación: lista vacía.
  Stream<List<IglesiaModel>> observarPendientesDeModeracion();

  /// Pasa a Aprobado (público). Lanza `PermisoDenegadoException` si no corresponde.
  Future<void> aprobar(String idIglesia);

  /// Pasa a Rechazado (deja de estar pendiente y nunca se publica).
  Future<void> rechazar(String idIglesia);

  /// Importadas de OpenStreetMap cuya denominación está "Por verificar"
  /// (solo el Administrador General; para los demás, lista vacía).
  Stream<List<IglesiaModel>> observarPorVerificar();

  /// El Administrador General confirma que la importada sí es de la
  /// denominación indicada (pasa a "Confirmada_OSM").
  Future<void> confirmarDenominacion(String idIglesia);

  /// El Administrador General descarta una importada que no es de la
  /// denominación: se borra y una nueva importación no la vuelve a crear.
  Future<void> descartarImportada(String idIglesia);

  /// Borrado físico: solo para el Administrador General.
  Future<void> eliminarDefinitivamente(String idIglesia);
}
