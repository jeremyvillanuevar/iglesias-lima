/// Se lanza cuando una acción necesita sesión iniciada y no la hay.
class SesionRequeridaException implements Exception {
  const SesionRequeridaException();

  @override
  String toString() => 'Debes iniciar sesión para hacer esto.';
}
