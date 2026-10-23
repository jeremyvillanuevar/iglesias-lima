import 'package:flutter/material.dart';

import '../../../core/config/terminologia.dart';
import '../../../data/models/iglesia_model.dart';
import 'chip_sin_administrador.dart';

/// Chip o ícono del estado de administración. Público: si aún no tiene
/// administrador, [ChipSinAdministrador]; si ya lo tiene, un check
/// verificado con tooltip. En iglesias no públicas no se muestra nada.
class ChipEstadoAdministracion extends StatelessWidget {
  const ChipEstadoAdministracion({
    super.key,
    required this.iglesia,
    required this.terminologia,
  });

  final IglesiaModel iglesia;
  final Terminologia terminologia;

  @override
  Widget build(BuildContext context) {
    if (!iglesia.esPublica) return const SizedBox.shrink();
    final estado =
        terminologia.estadoAdministracion(iglesia.estadoAdministracion);
    if (!iglesia.esAdministrada) {
      return ChipSinAdministrador(estado: iglesia.estadoAdministracion);
    }
    return Tooltip(
      message: estado,
      child: Icon(
        Icons.verified_outlined,
        size: 14,
        color: Theme.of(context).colorScheme.primary,
        semanticLabel: estado,
      ),
    );
  }
}
