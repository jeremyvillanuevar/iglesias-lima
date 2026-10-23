/// Ayuda a buscar sin importar mayúsculas ni tildes ("catolica" = "Católica").
abstract final class TextoBusqueda {
  static const Map<String, String> _sinTilde = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'à': 'a',
    'è': 'e',
    'ì': 'i',
    'ò': 'o',
    'ù': 'u',
  };

  static String normalizar(String texto) {
    final minus = texto.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in minus.runes) {
      final c = String.fromCharCode(rune);
      buffer.write(_sinTilde[c] ?? c);
    }
    return buffer.toString();
  }

  /// true si TODAS las palabras de [consulta] aparecen en alguno de los [campos].
  static bool coincide(String consulta, Iterable<String?> campos) {
    final palabras =
        normalizar(consulta).split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (palabras.isEmpty) return true;
    final texto = normalizar(campos.whereType<String>().join(' '));
    return palabras.every(texto.contains);
  }
}
