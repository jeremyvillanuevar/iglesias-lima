import 'package:flutter/material.dart';

/// Botón "Continuar con Google".
class BotonGoogle extends StatelessWidget {
  const BotonGoogle({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      icon: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFF4285F4)),
        child: const Text(
          'G',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      label: const Text('Continuar con Google'),
    );
  }
}
