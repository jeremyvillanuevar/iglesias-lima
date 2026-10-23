import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';

/// Etiqueta para iglesias que aún no tienen administrador ("Sin
/// administrador") o cuyo reclamo está en revisión ("Reclamo pendiente").
class ChipSinAdministrador extends StatelessWidget {
  const ChipSinAdministrador({super.key, required this.estado});

  final EstadoAdministracion estado;

  static const Color _color = Color(0xFF546E7A);

  @override
  Widget build(BuildContext context) {
    final pendiente = estado == EstadoAdministracion.reclamacionPendiente;
    return Tooltip(
      message: pendiente
          ? 'Alguien pidió administrar esta iglesia; está en revisión.'
          : 'Nadie administra esta iglesia todavía. Si eres su responsable, '
              'puedes reclamarla.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(pendiente ? Icons.schedule : Icons.person_off_outlined,
                size: 12, color: _color),
            const SizedBox(width: 4),
            Text(
              estado.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
