/// Validaciones de formularios. Cada método devuelve null si el valor es
/// válido o el mensaje de error que se muestra debajo del campo.
abstract final class Validators {
  static final RegExp _regexCorreo =
      RegExp(r'^[\w.+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}$');

  static String? requerido(String? valor, {String campo = 'Este campo'}) {
    if (valor == null || valor.trim().isEmpty) return '$campo es obligatorio.';
    return null;
  }

  static String? correo(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo.';
    if (!_regexCorreo.hasMatch(v)) return 'El correo no es válido.';
    return null;
  }

  static String? contrasena(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña.';
    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }

  static String? Function(String?) confirmarContrasena(
      String Function() original) {
    return (valor) {
      if (valor == null || valor.isEmpty) return 'Repite tu contraseña.';
      if (valor != original()) return 'Las contraseñas no coinciden.';
      return null;
    };
  }

  static String? nombre(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre.';
    if (v.length < 2) return 'El nombre es muy corto.';
    return null;
  }

  /// URL obligatoria (http o https).
  static String? url(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa un enlace (URL).';
    return esUrlValida(v)
        ? null
        : 'El enlace debe empezar con http:// o https://';
  }

  /// URL opcional: vacía es válida.
  static String? urlOpcional(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return null;
    return esUrlValida(v)
        ? null
        : 'El enlace debe empezar con http:// o https://';
  }

  static bool esUrlValida(String valor) {
    final uri = Uri.tryParse(valor.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Número entero dentro de un rango (por ejemplo, repeticiones).
  static String? enteroEnRango(String? valor,
      {required int min, required int max}) {
    final n = int.tryParse(valor?.trim() ?? '');
    if (n == null) return 'Ingresa un número.';
    if (n < min || n > max) return 'Debe estar entre $min y $max.';
    return null;
  }
}
