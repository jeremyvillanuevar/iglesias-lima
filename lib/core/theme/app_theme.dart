import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../config/app_flavor.dart';
import 'contraste_color.dart';

/// Colores y estilos de las apps de directorio (interfaz formal).
///
/// Es una "fábrica" de temas: cada app (flavor) aporta su color principal y
/// todo lo demás se comparte.
abstract final class AppTheme {
  static const Color acento = Color(0xFFC9A227); // dorado
  static const Color pendiente = Color(0xFFE08A00);
  static const Color rechazado = Color(0xFFC62828);

  /// Tema claro de la app [flavor].
  static ThemeData claro([AppFlavor flavor = AppFlavor.porDefecto]) {
    final primario = flavor.colorPrimario;
    final onPrimary = ContrasteColor.textoSobre(primario);
    final esquema = ColorScheme.fromSeed(
      seedColor: primario,
      primary: primario,
      onPrimary: onPrimary,
      secondary: acento,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: const Color(0xFFF7F7FA),
      appBarTheme: AppBarTheme(
        backgroundColor: primario,
        foregroundColor: onPrimary,
        iconTheme: IconThemeData(color: onPrimary),
        actionsIconTheme: IconThemeData(color: onPrimary),
        centerTitle: false,
      ),
      tabBarTheme: pestanasSobrePrimario(esquema),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide(color: Color(0xFFD9DCE3)),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// Color del pin según la denominación.
  static Color colorDenominacion(Denominacion d) {
    switch (d) {
      case Denominacion.catolica:
        return const Color(0xFF7B1FA2);
      case Denominacion.evangelica:
        return const Color(0xFF1565C0);
      case Denominacion.testigosJehova:
        return const Color(0xFF2E7D32);
      case Denominacion.santosUltimosDias:
        return const Color(0xFFEF6C00);
      case Denominacion.adventista:
        return const Color(0xFF00695C);
    }
  }

  /// Texto legible sobre el color de [d] (chips de denominación).
  static Color textoSobreDenominacion(Denominacion d) =>
      ContrasteColor.textoSobre(colorDenominacion(d));

  /// Tabs sobre el color primario (AppBar / TabBar del tema).
  static TabBarThemeData pestanasSobrePrimario(ColorScheme c) =>
      TabBarThemeData(
        labelColor: c.onPrimary,
        unselectedLabelColor: c.onPrimary.withValues(
            alpha: ContrasteColor.opacidadLegible(c.onPrimary, c.primary)),
        indicatorColor: c.onPrimary,
        dividerColor: Colors.transparent,
      );

  /// Tabs sobre la superficie (bottom sheet, etc.).
  static TabBarThemeData pestanasSobreSuperficie(ColorScheme c) =>
      TabBarThemeData(
        labelColor: c.primary,
        unselectedLabelColor: c.onSurfaceVariant,
        indicatorColor: c.primary,
        dividerColor: Colors.transparent,
      );

  /// Tono (0-360) para los pines de Google Maps, cercano a [colorDenominacion].
  static double tonoDenominacion(Denominacion d) {
    switch (d) {
      case Denominacion.catolica:
        return 285; // violeta
      case Denominacion.evangelica:
        return 215; // azul
      case Denominacion.testigosJehova:
        return 120; // verde
      case Denominacion.santosUltimosDias:
        return 30; // naranja
      case Denominacion.adventista:
        return 170; // teal
    }
  }

  static IconData iconoActividad(TipoActividad t) {
    switch (t) {
      case TipoActividad.misa:
        return Icons.church;
      case TipoActividad.culto:
        return Icons.music_note;
      case TipoActividad.reunion:
        return Icons.groups;
    }
  }
}
