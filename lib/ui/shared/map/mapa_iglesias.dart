import 'package:flutter/material.dart';

import '../../../core/config/maps_config.dart';
import 'controlador_mapa.dart';
import 'coordenada_mapa.dart';
import 'disponibilidad/disponibilidad_google_maps.dart';
import 'mapa_google.dart';
import 'mapa_osm.dart';
import 'marcador_mapa.dart';

/// ÚNICO widget de mapa que usan las pantallas.
///
/// - Clave de Google Maps real (lib/core/config/maps_config.dart) y Google
///   Maps disponible => Google Maps.
/// - Clave placeholder, Google Maps todavía cargando (web) o falló en
///   tiempo de ejecución => OpenStreetMap (respaldo automático).
/// Ambos con agrupación de pines (clustering).
class MapaIglesias extends StatelessWidget {
  const MapaIglesias({
    super.key,
    required this.marcadores,
    required this.centroInicial,
    this.zoomInicial = 12,
    this.onMarcadorTap,
    this.onMapaTap,
    this.controlador,
    this.agrupar = true,
    this.ubicacionUsuario,
    this.forzarProveedor,
  });

  final List<MarcadorMapa> marcadores;
  final CoordenadaMapa centroInicial;
  final double zoomInicial;
  final ValueChanged<String>? onMarcadorTap;
  final ValueChanged<CoordenadaMapa>? onMapaTap;
  final ControladorMapa? controlador;
  final bool agrupar;

  /// Punto azul con la posición del usuario (si dio permiso).
  final CoordenadaMapa? ubicacionUsuario;

  /// Solo para pruebas: true = Google, false = OSM, null = automático.
  final bool? forzarProveedor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MapsConfig.respaldoOsm,
      builder: (context, _, __) => ValueListenableBuilder<EstadoGoogleMaps>(
        valueListenable: DisponibilidadGoogleMaps.estado,
        builder: (context, estado, __) {
          final usarGoogle = forzarProveedor ??
              (MapsConfig.usarGoogleMaps && estado == EstadoGoogleMaps.listo);
          return usarGoogle ? _google() : _osm();
        },
      ),
    );
  }

  Widget _google() => MapaGoogle(
        marcadores: marcadores,
        centroInicial: centroInicial,
        zoomInicial: zoomInicial,
        onMarcadorTap: onMarcadorTap,
        onMapaTap: onMapaTap,
        controlador: controlador,
        agrupar: agrupar,
        ubicacionUsuario: ubicacionUsuario,
        onFallo: MapsConfig.activarRespaldoOsm,
      );

  Widget _osm() => MapaOsm(
        marcadores: marcadores,
        centroInicial: centroInicial,
        zoomInicial: zoomInicial,
        onMarcadorTap: onMarcadorTap,
        onMapaTap: onMapaTap,
        controlador: controlador,
        agrupar: agrupar,
        ubicacionUsuario: ubicacionUsuario,
      );
}
