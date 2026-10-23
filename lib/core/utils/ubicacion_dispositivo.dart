import 'package:geolocator/geolocator.dart';

import '../../ui/shared/map/coordenada_mapa.dart';

/// Error al obtener la ubicación, con un mensaje para el usuario.
class UbicacionNoDisponible implements Exception {
  const UbicacionNoDisponible(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Pide permiso y obtiene la ubicación actual del teléfono (GPS).
class UbicacionDispositivo {
  const UbicacionDispositivo();

  Future<CoordenadaMapa> obtener() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UbicacionNoDisponible(
          'Activa la ubicación (GPS) de tu teléfono para usar esta opción.');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw const UbicacionNoDisponible(
          'No diste permiso para usar tu ubicación.');
    }
    if (permiso == LocationPermission.deniedForever) {
      throw const UbicacionNoDisponible(
          'El permiso de ubicación está bloqueado. Actívalo en Ajustes > Apps.');
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return CoordenadaMapa(p.latitude, p.longitude);
  }
}
