import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';

/// Campo "Denominación" reutilizable en los formularios.
///
/// En las Apps de una sola denominación (Apps 1 a 4) se muestra fijo
/// (solo lectura); en la App 5 es una lista desplegable.
class CampoDenominacion extends StatelessWidget {
  const CampoDenominacion({
    super.key,
    required this.valor,
    required this.bloqueada,
    this.onCambio,
    this.ayuda,
  });

  final Denominacion valor;
  final bool bloqueada;
  final ValueChanged<Denominacion>? onCambio;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    if (bloqueada) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Denominación',
          helperText: ayuda,
          helperMaxLines: 2,
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        child: Row(children: [
          CircleAvatar(
              radius: 6, backgroundColor: AppTheme.colorDenominacion(valor)),
          const SizedBox(width: 8),
          Expanded(child: Text(valor.label)),
        ]),
      );
    }
    return DropdownButtonFormField<Denominacion>(
      isExpanded: true,
      initialValue: valor,
      decoration: InputDecoration(
        labelText: 'Denominación *',
        helperText: ayuda,
        helperMaxLines: 2,
      ),
      items: [
        for (final d in Denominacion.values)
          DropdownMenuItem(
            value: d,
            child: Row(children: [
              CircleAvatar(
                  radius: 6, backgroundColor: AppTheme.colorDenominacion(d)),
              const SizedBox(width: 8),
              Expanded(child: Text(d.label, overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ],
      onChanged: onCambio == null
          ? null
          : (d) {
              if (d != null) onCambio!(d);
            },
    );
  }
}
