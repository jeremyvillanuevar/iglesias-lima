import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentReference, GeoPoint;

import '../models/enums.dart';
import '../models/ministerio_model.dart';

/// Contrato de ministerios que usan los ViewModels (RF-3.1 a RF-3.3).
///
/// Implementaciones: `FirebaseMinisterioRepository` y `DemoMinisterioRepository`.
abstract class MinisterioRepository {
  DocumentReference<Map<String, dynamic>> refDe(String idMinisterio);

  Future<MinisterioModel?> obtener(String idMinisterio);

  /// Ministerios aprobados de una iglesia.
  Stream<List<MinisterioModel>> observarPorIglesia(String idIglesia);

  /// Ministerios que coordino (incluye Pendientes).
  Stream<List<MinisterioModel>> observarMisMinisterios();

  /// Crea un ministerio Pendiente; el creador queda como coordinador
  /// ("Administrador de Ministerio", RF-3.1). Devuelve su id.
  ///
  /// - [TipoUbicacionMinisterio.iglesia]: requiere [idIglesia] (RF-3.2).
  /// - [TipoUbicacionMinisterio.fisica]: independiente con [ubicacionPropia],
  ///   [pais] y [localidad] (RF-3.3).
  /// - [TipoUbicacionMinisterio.virtual]: independiente con [linkVirtual].
  Future<String> crearMinisterio({
    required String nombre,
    required TipoUbicacionMinisterio tipoUbicacion,
    String? idIglesia,
    GeoPoint? ubicacionPropia,
    String? linkVirtual,
    Denominacion? denominacion,
    String? pais,
    String? localidad,
  });

  Future<void> actualizar(MinisterioModel ministerio);

  Future<void> eliminar(String idMinisterio);

  // ---------- Moderación (pantalla de Administración) ----------
  /// Pendientes que el usuario actual puede moderar: el Administrador General
  /// ve todos; un Pastor/Padre solo los de las iglesias que lidera.
  /// Sin sesión o sin rol de moderación: lista vacía.
  Stream<List<MinisterioModel>> observarPendientesDeModeracion();

  /// Pasa a Aprobado (público). Lanza `PermisoDenegadoException` si no corresponde.
  Future<void> aprobar(String idMinisterio);

  /// Pasa a Rechazado (deja de estar pendiente y nunca se publica).
  Future<void> rechazar(String idMinisterio);

  Future<void> eliminarDefinitivamente(String idMinisterio);
}
