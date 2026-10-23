import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formato_fechas.dart';
import '../../../data/recurrencia/resultado_recurrencia.dart';

/// Resumen de cuántos eventos se crearán y entre qué fechas.
class VistaPreviaRecurrencia extends StatelessWidget {
  const VistaPreviaRecurrencia({
    super.key,
    required this.resultado,
    this.horariosPasados = 0,
  });

  final ResultadoRecurrencia? resultado;
  final int horariosPasados;

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final tema = Theme.of(context);
    final lineas = <String>[];
    if (r == null || r.ocurrencias.isEmpty) {
      lineas.add('Elige al menos una hora futura para ver las fechas.');
    } else {
      final primera = r.ocurrencias.first.inicio;
      final ultima = r.ocurrencias.last.inicio;
      lineas.add(r.cantidad == 1
          ? 'Se creará 1 evento: ${FormatoFechas.diaYHora(primera)}.'
          : 'Se crearán ${r.cantidad} eventos, del ${FormatoFechas.diaCorto(primera)} '
              'al ${FormatoFechas.diaCorto(ultima)}.');
      if (r.recortadoPorMaximo) {
        lineas.add(
            'Se limitó a ${AppConstants.maxOcurrenciasRecurrencia} eventos '
            'por vez. Puedes clonar después para seguir.');
      }
      if (r.recortadoPorVentana) {
        lineas.add('No se crean fechas más allá de '
            '${AppConstants.historialMaxMeses} meses.');
      }
    }
    if (horariosPasados > 0) {
      lineas.add('Se omiten $horariosPasados horario(s) que ya pasaron.');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_repeat),
          const SizedBox(width: 10),
          Expanded(child: Text(lineas.join('\n'))),
        ],
      ),
    );
  }
}
