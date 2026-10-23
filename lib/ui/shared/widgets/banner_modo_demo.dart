import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_flavor.dart';
import '../../../core/config/configuracion_app.dart';

/// Chip discreto que avisa que la app está en Modo Demo, con el nombre de
/// la app (flavor). No se muestra nada cuando Firebase está configurado.
class BannerModoDemo extends StatelessWidget {
  const BannerModoDemo({super.key});

  /// Texto del chip para la app [flavor].
  static String textoPara(AppFlavor flavor) =>
      '${flavor.nombreApp} · Modo Demo (sin Firebase)';

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracionApp>();
    if (!config.modoDemo) return const SizedBox.shrink();

    return Material(
      color: Colors.amber.shade100.withValues(alpha: 0.95),
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFFE0B000))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _explicar(context, config),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.science_outlined,
                  size: 16, color: Color(0xFF6D4C00)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  textoPara(config.flavor),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D4C00),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _explicar(BuildContext context, ConfiguracionApp config) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${config.flavor.nombreApp} · Modo Demo'),
        content: Text(
          'La app está usando datos de EJEMPLO guardados solo en la memoria '
          'del teléfono. Puedes iniciar sesión con cualquier correo y una '
          'contraseña de 6 caracteres o más, y crear iglesias, ministerios y '
          'eventos.\n\n'
          'Al entrar eres Administrador General (de prueba): desde el menú de '
          'tu cuenta puedes cambiar de rol y abrir la pantalla de Moderación '
          'para Aprobar o Rechazar lo Pendiente.\n\n'
          'Todo se borra al cerrar la app. Para usar datos reales, conecta '
          'Firebase siguiendo COMO_CONECTAR_FIREBASE_Y_MAPS.md.'
          '${config.motivoModoDemo != null ? '\n\nDetalle: ${config.motivoModoDemo}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
