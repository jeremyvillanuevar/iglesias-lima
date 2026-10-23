import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Contraste de colores (WCAG 2.1). Usado para garantizar que el texto
/// sobre el color primario de cada flavor sea legible.
abstract final class ContrasteColor {
  /// Luminancia relativa (0–1) de [c] según sRGB / WCAG.
  static double luminancia(Color c) {
    double canal(double v) {
      final n = v / 255.0;
      return n <= 0.03928
          ? n / 12.92
          : math.pow((n + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * canal(c.r * 255) +
        0.7152 * canal(c.g * 255) +
        0.0722 * canal(c.b * 255);
  }

  /// Ratio de contraste entre [a] y [b] (≥1).
  static double razon(Color a, Color b) {
    final l1 = luminancia(a);
    final l2 = luminancia(b);
    final claro = math.max(l1, l2);
    final oscuro = math.min(l1, l2);
    return (claro + 0.05) / (oscuro + 0.05);
  }

  /// Blanco o negro, el que contraste más con [fondo].
  static Color textoSobre(Color fondo) {
    final blanco = razon(Colors.white, fondo);
    final negro = razon(Colors.black, fondo);
    return blanco >= negro ? Colors.white : Colors.black;
  }

  /// Mínimo WCAG AA para texto normal.
  static const double minimoTexto = 4.5;

  /// Opacidad (≥ [inicio]) del color [sobre] sobre [fondo] que alcanza
  /// [minimoTexto]. Si ni con opacidad 1 se llega, devuelve 1.
  static double opacidadLegible(
    Color sobre,
    Color fondo, {
    double inicio = 0.7,
    double paso = 0.05,
  }) {
    for (var o = inicio; o <= 1.0 + 1e-9; o += paso) {
      final mezclado = Color.lerp(fondo, sobre, o.clamp(0.0, 1.0))!;
      if (razon(mezclado, fondo) >= minimoTexto) return o.clamp(0.0, 1.0);
    }
    return 1.0;
  }

  /// Mezcla [sobre] sobre [fondo] con la opacidad de [opacidadLegible].
  static Color mezclar(Color sobre, Color fondo, {double inicio = 0.7}) {
    final o = opacidadLegible(sobre, fondo, inicio: inicio);
    return Color.lerp(fondo, sobre, o)!;
  }
}
