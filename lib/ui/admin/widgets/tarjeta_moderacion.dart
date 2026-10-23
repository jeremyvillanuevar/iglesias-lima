import 'package:flutter/material.dart';

import '../../shared/widgets/chip_pendiente.dart';

/// Tarjeta de un elemento Pendiente con los botones de moderación:
/// Rechazar, Aprobar y (solo Admin General) Borrar definitivamente.
class TarjetaModeracion extends StatelessWidget {
  const TarjetaModeracion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.lineas,
    required this.ocupado,
    required this.esPropio,
    required this.alAprobar,
    required this.alRechazar,
    this.alBorrar,
    this.insignia = const ChipPendiente(),
    this.textoAprobar = 'Aprobar',
    this.textoRechazar = 'Rechazar',
    this.detalle,
  });

  final IconData icono;
  final String titulo;
  final List<String> lineas;
  final bool ocupado;

  /// Lo creó el usuario actual (y no es Admin): no puede moderarlo.
  final bool esPropio;
  final VoidCallback alAprobar;
  final VoidCallback alRechazar;

  /// null = no se muestra el botón de borrado definitivo.
  final VoidCallback? alBorrar;

  /// Etiqueta a la derecha del título (por defecto "Pendiente").
  final Widget insignia;
  final String textoAprobar;
  final String textoRechazar;

  /// Contenido opcional bajo el título (procedencia, chips…).
  final Widget? detalle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final habilitado = !ocupado && !esPropio;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: tema.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(titulo,
                      style: tema.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                insignia,
              ],
            ),
            if (detalle != null)
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 4),
                child: detalle!,
              ),
            const SizedBox(height: 6),
            for (final l in lineas)
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 2),
                child: Text(l, style: tema.textTheme.bodySmall),
              ),
            if (esPropio)
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 6),
                child: Text(
                  'Lo creaste tú: debe aprobarlo otro moderador.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (alBorrar != null)
                  TextButton.icon(
                    onPressed: ocupado ? null : alBorrar,
                    style: TextButton.styleFrom(
                        foregroundColor: tema.colorScheme.error),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Borrar'),
                  ),
                OutlinedButton.icon(
                  onPressed: habilitado ? alRechazar : null,
                  icon: const Icon(Icons.close),
                  label: Text(textoRechazar),
                ),
                FilledButton.icon(
                  onPressed: habilitado ? alAprobar : null,
                  icon: ocupado
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(textoAprobar),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
