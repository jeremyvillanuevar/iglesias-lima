import 'package:flutter/material.dart';

import 'coordenada_mapa.dart';

/// Un pin del mapa (normalmente una iglesia).
class MarcadorMapa {
  const MarcadorMapa({
    required this.id,
    required this.posicion,
    required this.titulo,
    this.subtitulo,
    this.color = Colors.red,
    this.pendiente = false,
    this.porVerificar = false,
  });

  final String id;
  final CoordenadaMapa posicion;
  final String titulo;
  final String? subtitulo;
  final Color color;

  /// Se dibuja con borde punteado/naranja si está Pendiente.
  final bool pendiente;

  /// Indicador discreto (solo para el Administrador General): importada de
  /// OpenStreetMap con la denominación por verificar.
  final bool porVerificar;
}
