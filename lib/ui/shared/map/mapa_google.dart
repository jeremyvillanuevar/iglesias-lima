import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'controlador_mapa.dart';
import 'disponibilidad/disponibilidad_google_maps.dart';
import 'coordenada_mapa.dart';
import 'marcador_mapa.dart';

/// Mapa con Google Maps. Solo se usa cuando hay una clave real configurada.
///
/// Si el mapa nativo no llega a crearse en [tiempoMaximoCreacion] (por
/// ejemplo, sin Google Play Services), llama a [onFallo] para que la app pase
/// a OpenStreetMap.
class MapaGoogle extends StatefulWidget {
  const MapaGoogle({
    super.key,
    required this.marcadores,
    required this.centroInicial,
    required this.zoomInicial,
    this.onMarcadorTap,
    this.onMapaTap,
    this.controlador,
    this.agrupar = true,
    this.ubicacionUsuario,
    this.onFallo,
  });

  final List<MarcadorMapa> marcadores;
  final CoordenadaMapa centroInicial;
  final double zoomInicial;
  final ValueChanged<String>? onMarcadorTap;
  final ValueChanged<CoordenadaMapa>? onMapaTap;
  final ControladorMapa? controlador;
  final bool agrupar;
  final CoordenadaMapa? ubicacionUsuario;

  /// Se llama si Google Maps no logra iniciarse.
  final VoidCallback? onFallo;

  static const Duration tiempoMaximoCreacion = Duration(seconds: 15);

  @override
  State<MapaGoogle> createState() => _MapaGoogleState();
}

class _MapaGoogleState extends State<MapaGoogle> {
  static const ClusterManagerId _idClusters = ClusterManagerId('iglesias');
  GoogleMapController? _controller;
  Timer? _vigilante;

  @override
  void initState() {
    super.initState();
    _vigilante = Timer(MapaGoogle.tiempoMaximoCreacion, () {
      if (mounted && _controller == null) widget.onFallo?.call();
    });
  }

  @override
  void dispose() {
    _vigilante?.cancel();
    widget.controlador?.desvincular();
    _controller?.dispose();
    super.dispose();
  }

  void _alCrearMapa(GoogleMapController controller) {
    _controller = controller;
    _vigilante?.cancel();
    widget.controlador?.vincular((destino, zoom) {
      final punto = LatLng(destino.latitud, destino.longitud);
      _controller?.animateCamera(
        zoom == null
            ? CameraUpdate.newLatLng(punto)
            : CameraUpdate.newLatLngZoom(punto, zoom),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final agrupar =
        widget.agrupar && DisponibilidadGoogleMaps.agrupacionDisponible;
    final marcadores = <Marker>{
      for (final m in widget.marcadores)
        Marker(
          markerId: MarkerId(m.id),
          position: LatLng(m.posicion.latitud, m.posicion.longitud),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            m.pendiente
                ? BitmapDescriptor.hueOrange
                : HSVColor.fromColor(m.color).hue,
          ),
          alpha: m.porVerificar ? 0.6 : 1,
          infoWindow: InfoWindow(title: m.titulo, snippet: m.subtitulo),
          clusterManagerId: agrupar ? _idClusters : null,
          onTap: () => widget.onMarcadorTap?.call(m.id),
        ),
      if (widget.ubicacionUsuario != null)
        Marker(
          markerId: const MarkerId('__mi_ubicacion__'),
          position: LatLng(
            widget.ubicacionUsuario!.latitud,
            widget.ubicacionUsuario!.longitud,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Estás aquí'),
          zIndexInt: 1,
        ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target:
            LatLng(widget.centroInicial.latitud, widget.centroInicial.longitud),
        zoom: widget.zoomInicial,
      ),
      markers: marcadores,
      clusterManagers: agrupar
          ? {const ClusterManager(clusterManagerId: _idClusters)}
          : const <ClusterManager>{},
      onMapCreated: _alCrearMapa,
      onTap: widget.onMapaTap == null
          ? null
          : (p) => widget.onMapaTap!(CoordenadaMapa(p.latitude, p.longitude)),
      // Deja el logo de Google por encima de la barra de navegación.
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
