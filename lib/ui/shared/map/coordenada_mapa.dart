/// Latitud/longitud propia de la app, para no atar las pantallas a un
/// proveedor de mapas (Google Maps u OpenStreetMap).
class CoordenadaMapa {
  const CoordenadaMapa(this.latitud, this.longitud);

  final double latitud;
  final double longitud;

  @override
  bool operator ==(Object other) =>
      other is CoordenadaMapa &&
      other.latitud == latitud &&
      other.longitud == longitud;

  @override
  int get hashCode => Object.hash(latitud, longitud);

  @override
  String toString() =>
      '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}';
}
