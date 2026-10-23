import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/maps_config.dart';
import 'controlador_mapa.dart';
import 'coordenada_mapa.dart';
import 'marcador_mapa.dart';

/// Mapa con OpenStreetMap (flutter_map). Funciona sin ninguna clave.
class MapaOsm extends StatefulWidget {
  const MapaOsm({
    super.key,
    required this.marcadores,
    required this.centroInicial,
    required this.zoomInicial,
    this.onMarcadorTap,
    this.onMapaTap,
    this.controlador,
    this.agrupar = true,
    this.ubicacionUsuario,
  });

  final List<MarcadorMapa> marcadores;
  final CoordenadaMapa centroInicial;
  final double zoomInicial;
  final ValueChanged<String>? onMarcadorTap;
  final ValueChanged<CoordenadaMapa>? onMapaTap;
  final ControladorMapa? controlador;
  final bool agrupar;
  final CoordenadaMapa? ubicacionUsuario;

  @override
  State<MapaOsm> createState() => _MapaOsmState();
}

class _MapaOsmState extends State<MapaOsm> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant MapaOsm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      oldWidget.controlador?.desvincular();
      _vincular();
    }
  }

  @override
  void dispose() {
    widget.controlador?.desvincular();
    _mapController.dispose();
    super.dispose();
  }

  void _vincular() {
    widget.controlador?.vincular((destino, zoom) {
      _mapController.move(
        ll.LatLng(destino.latitud, destino.longitud),
        zoom ?? _mapController.camera.zoom,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final marcadores = widget.marcadores.map(_marcador).toList();
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: ll.LatLng(
            widget.centroInicial.latitud, widget.centroInicial.longitud),
        initialZoom: widget.zoomInicial,
        minZoom: 3,
        maxZoom: 19,
        onMapReady: _vincular,
        onTap: widget.onMapaTap == null
            ? null
            : (_, punto) => widget
                .onMapaTap!(CoordenadaMapa(punto.latitude, punto.longitude)),
      ),
      children: [
        TileLayer(
          urlTemplate: MapsConfig.urlTeselasOsm,
          userAgentPackageName: MapsConfig.userAgentPaquete,
          maxZoom: 19,
        ),
        if (widget.ubicacionUsuario != null)
          MarkerLayer(markers: [_puntoUsuario(widget.ubicacionUsuario!)]),
        if (widget.agrupar)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              markers: marcadores,
              maxClusterRadius: 45,
              size: const Size(42, 42),
              alignment: Alignment.center,
              disableClusteringAtZoom: 17,
              onMarkerTap: (m) {
                final key = m.key;
                if (key is ValueKey<String>) {
                  widget.onMarcadorTap?.call(key.value);
                }
              },
              builder: (context, grupo) => _Cluster(cantidad: grupo.length),
            ),
          )
        else
          MarkerLayer(markers: marcadores),
        // SafeArea: con la app de borde a borde, el crédito no debe quedar
        // debajo de la barra de navegación del sistema.
        SafeArea(
          top: false,
          child: RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            showFlutterMapAttribution: false,
            attributions: [
              TextSourceAttribution(
                '© colaboradores de OpenStreetMap',
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Marker _marcador(MarcadorMapa m) {
    return Marker(
      key: ValueKey<String>(m.id),
      point: ll.LatLng(m.posicion.latitud, m.posicion.longitud),
      width: 44,
      height: 44,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        // Solo se usa cuando no hay agrupación (en el clúster manda onMarkerTap).
        onTap: widget.agrupar ? null : () => widget.onMarcadorTap?.call(m.id),
        child: Tooltip(
          message: m.subtitulo == null || m.subtitulo!.isEmpty
              ? m.titulo
              : '${m.titulo}\n${m.subtitulo}',
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 44,
                color: m.pendiente
                    ? Colors.orange.shade700
                    : m.porVerificar
                        ? m.color.withValues(alpha: 0.6)
                        : m.color,
                shadows: const [Shadow(blurRadius: 3, color: Colors.black38)],
              ),
              Positioned(
                top: 9,
                child: Icon(
                  m.pendiente
                      ? Icons.hourglass_top
                      : m.porVerificar
                          ? Icons.help_outline
                          : Icons.church,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Marker _puntoUsuario(CoordenadaMapa c) {
    return Marker(
      point: ll.LatLng(c.latitud, c.longitud),
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
      ),
    );
  }
}

/// Círculo con el número de iglesias agrupadas.
class _Cluster extends StatelessWidget {
  const _Cluster({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      alignment: Alignment.center,
      child: Text(
        '$cantidad',
        style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
