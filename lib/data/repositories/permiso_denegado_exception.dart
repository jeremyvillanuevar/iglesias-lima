/// Se lanza cuando el usuario no tiene permiso para una acción
/// (mismas reglas que firestore.rules).
class PermisoDenegadoException implements Exception {
  const PermisoDenegadoException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
