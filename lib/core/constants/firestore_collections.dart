/// Nombres exactos de las colecciones en Firestore.
/// Si cambias uno aquí, cámbialo también en firestore.rules.
abstract final class FirestoreCollections {
  static const String users = 'users';
  static const String iglesias = 'iglesias';
  static const String ministerios = 'ministerios';
  static const String eventos = 'eventos';

  /// Pedidos para administrar una iglesia "Sin administrador" (p. ej. las
  /// importadas de OpenStreetMap). Solo el Admin General las aprueba.
  static const String solicitudesReclamo = 'solicitudes_reclamo';

  /// Iglesias de OpenStreetMap que el Admin General descartó (no eran de
  /// la denominación). La importación las salta para no volver a crearlas.
  static const String osmDescartadas = 'osm_descartadas';

  /// App 6 (Gamificación, Fase 2). Reservada, todavía sin uso.
  static const String checkins = 'checkins';
}
