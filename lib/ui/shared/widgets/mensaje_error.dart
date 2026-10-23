import 'package:flutter/material.dart';

/// Mensaje de error amable, con botón opcional para reintentar.
class MensajeError extends StatelessWidget {
  const MensajeError({
    super.key,
    required this.mensaje,
    this.alReintentar,
    this.icono = Icons.error_outline,
  });

  final String mensaje;
  final VoidCallback? alReintentar;
  final IconData icono;

  /// Muestra el error abajo en un SnackBar (para acciones puntuales).
  static void mostrarSnack(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: colores.error, size: 40),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            if (alReintentar != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: alReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
