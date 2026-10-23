import 'package:flutter/material.dart';

/// Indicador de carga centrado, con un texto opcional.
class Cargando extends StatelessWidget {
  const Cargando({super.key, this.mensaje});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (mensaje != null) ...[
              const SizedBox(height: 12),
              Text(mensaje!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
