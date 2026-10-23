import 'package:flutter/material.dart';

/// Indicador discreto "Por verificar" para iglesias importadas de
/// OpenStreetMap cuya denominación solo se dedujo por el nombre. Solo lo ve
/// el Administrador General.
class ChipPorVerificar extends StatelessWidget {
  const ChipPorVerificar({super.key, this.sinMarcador = false});

  /// true = sin etiqueta ni marca en el nombre (revisar una a una).
  final bool sinMarcador;

  static const Color _color = Color(0xFF8D6E63);

  @override
  Widget build(BuildContext context) {
    final texto =
        sinMarcador ? 'por verificar · sin marcador' : 'por verificar';
    final tip = sinMarcador
        ? 'Sin etiqueta de denominación ni marca en el nombre: revisa si '
            'corresponde. Confírmala o descártala en Moderación → Por verificar.'
        : 'Denominación deducida por el nombre: confírmala o descártala '
            'en Moderación → Por verificar.';
    return Tooltip(
      message: tip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline, size: 12, color: _color),
          const SizedBox(width: 3),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
