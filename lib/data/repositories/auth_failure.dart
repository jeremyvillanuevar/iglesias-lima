/// Error de autenticación con un mensaje listo para mostrar en pantalla.
class AuthFailure implements Exception {
  const AuthFailure(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}
