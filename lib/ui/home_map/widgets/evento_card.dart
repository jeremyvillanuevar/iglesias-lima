import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato_fechas.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/evento_model.dart';
import '../../shared/widgets/chip_pendiente.dart';

/// Tarjeta de un evento (misa, culto o reunión) con la acción "Clonar Evento".
class EventoCard extends StatelessWidget {
  const EventoCard({
    super.key,
    required this.evento,
    this.onClonar,
    this.vencido = false,
  });

  final EventoModel evento;

  /// Abre el formulario con los datos de este evento (RF-4.4). null = oculto.
  final VoidCallback? onClonar;

  /// true en la pestaña "Historial/Vencidos" (se muestra más tenue).
  final bool vencido;

  static const String textoClonar = 'Clonar Evento';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final e = evento;
    final pendiente = e.estadoAprobacion == EstadoAprobacion.pendiente;
    final horario = e.fechaHoraFin == null
        ? FormatoFechas.diaYHora(e.fechaHoraInicio)
        : '${FormatoFechas.diaYHora(e.fechaHoraInicio)} – ${FormatoFechas.hora(e.fechaHoraFin!)}';

    return Opacity(
      opacity: vencido ? 0.75 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (e.imagenUrl != null && e.imagenUrl!.isNotEmpty)
              Image.network(
                e.imagenUrl!,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: tema.colorScheme.primaryContainer,
                    child: Icon(AppTheme.iconoActividad(e.tipoActividad),
                        size: 18, color: tema.colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.titulo,
                            style: tema.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.schedule, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(horario,
                                  style: tema.textTheme.bodySmall)),
                        ]),
                      ],
                    ),
                  ),
                  if (pendiente) const ChipPendiente(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Etiqueta(
                      texto: e.tipoActividad.label, icono: Icons.label_outline),
                  _Etiqueta(texto: e.categoria, icono: Icons.sell_outlined),
                  if (e.esVirtual)
                    const _Etiqueta(
                        texto: 'Virtual', icono: Icons.videocam_outlined),
                  if (e.esRecurrente && e.patronRecurrencia != null)
                    _Etiqueta(
                      texto: describirPatron(e.patronRecurrencia!),
                      icono: Icons.repeat,
                    ),
                ],
              ),
            ),
            if (e.descripcion != null && e.descripcion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  e.descripcion!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (e.esVirtual && e.linkVirtual != null && !vencido)
                    TextButton.icon(
                      onPressed: () => _abrir(context, e.linkVirtual!),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Unirse en línea'),
                    ),
                  if (onClonar != null)
                    TextButton.icon(
                      onPressed: onClonar,
                      icon: const Icon(Icons.copy_all_outlined, size: 18),
                      label: const Text(textoClonar),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Semanal_07:00" -> "Semanal · 07:00".
  static String describirPatron(String patron) {
    final partes = patron.split('_');
    if (partes.length != 2) return patron;
    final tipo = partes.first == 'Turno' ? 'Turno' : partes.first;
    return '$tipo · ${partes.last}';
  }

  Future<void> _abrir(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')));
    }
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12),
          const SizedBox(width: 4),
          Text(texto, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
