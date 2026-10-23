import 'app_flavor.dart';

/// Cómo arrancó la app: qué app del ecosistema es (flavor) y si usa
/// Firebase real o el Modo Demo (datos en memoria).
class ConfiguracionApp {
  const ConfiguracionApp({
    required this.modoDemo,
    this.motivoModoDemo,
    this.flavor = AppFlavor.porDefecto,
  });

  /// true = no hay Firebase configurado; todo funciona en memoria.
  final bool modoDemo;

  /// Explicación técnica de por qué se entró al Modo Demo (para depurar).
  final String? motivoModoDemo;

  /// App del ecosistema que se está ejecutando (Apps 1 a 5).
  final AppFlavor flavor;
}
