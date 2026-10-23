/// Configuración del inicio de sesión con Google.
///
/// [webClientId] es el "ID de cliente web" (OAuth, tipo 3) del proyecto
/// iglesias-lima. En Android se pasa como `serverClientId` para que Google
/// entregue el idToken que Firebase Auth necesita; en web es el `clientId`
/// (también está en la etiqueta meta google-signin-client_id de
/// web/index.html). Lo encuentras en Firebase Console > Authentication >
/// Método de acceso > Google > "Configuración del SDK web".
///
/// El cliente OAuth de Android (tipo 1) NO se escribe aquí: Google lo
/// identifica por el paquete + la huella SHA-1 de android/app/debug.keystore
/// (ver android/app/src/catolica/google-services.json).
abstract final class GoogleSignInConfig {
  static const String webClientId =
      '229289277006-u8vvk0ovkorn0l81416ud088m42db0si.apps.googleusercontent.com';

  /// null mientras siga el texto de ejemplo.
  static String? get serverClientIdOrNull =>
      webClientId.contains('PEGA_AQUI') ? null : webClientId;
}
