import 'package:flutter/material.dart';

import '../../../data/recurrencia/hora_del_dia.dart';

/// Chips de horas: rápidas (7:00, 12:00, 17:00, 19:00) y personalizadas.
class SelectorTurnos extends StatelessWidget {
  const SelectorTurnos({
    super.key,
    required this.seleccionados,
    required this.rapidos,
    required this.onAlternar,
    required this.onQuitar,
    required this.onAgregar,
  });

  final List<HoraDelDia> seleccionados;
  final List<HoraDelDia> rapidos;
  final ValueChanged<HoraDelDia> onAlternar;
  final ValueChanged<HoraDelDia> onQuitar;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final personalizados =
        seleccionados.where((h) => !rapidos.contains(h)).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final h in rapidos)
          FilterChip(
            label: Text(h.texto),
            selected: seleccionados.contains(h),
            onSelected: (_) => onAlternar(h),
          ),
        for (final h in personalizados)
          InputChip(
            label: Text(h.texto),
            selected: true,
            onDeleted: () => onQuitar(h),
            deleteButtonTooltipMessage: 'Quitar',
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Otra hora'),
          onPressed: onAgregar,
        ),
      ],
    );
  }
}
