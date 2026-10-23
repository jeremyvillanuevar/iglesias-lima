import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Etiqueta "Pendiente" para iglesias y eventos aún no aprobados (RF-2.4, RF-4.5).
class ChipPendiente extends StatelessWidget {
  const ChipPendiente({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Pendiente de aprobación: solo lo ves tú y tu aprobador.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.pendiente.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.pendiente),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top, size: 12, color: AppTheme.pendiente),
            SizedBox(width: 4),
            Text(
              'Pendiente',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.pendiente,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
