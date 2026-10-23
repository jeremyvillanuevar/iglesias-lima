import 'package:flutter/material.dart';

import '../../../core/config/terminologia.dart';
import '../../../data/models/iglesia_model.dart';

/// Línea gris con la procedencia de la iglesia ('OpenStreetMap',
/// 'Informada por…', 'Verificada'). No va en el pin del mapa.
class LineaProcedencia extends StatelessWidget {
  const LineaProcedencia({
    super.key,
    required this.iglesia,
    required this.terminologia,
  });

  final IglesiaModel iglesia;
  final Terminologia terminologia;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Text(
      terminologia.procedenciaDe(iglesia),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: tema.textTheme.bodySmall?.copyWith(
        color: tema.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
