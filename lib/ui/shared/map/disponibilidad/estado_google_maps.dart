/// Estado de carga de Google Maps en la plataforma actual.
enum EstadoGoogleMaps {
  /// Todavía cargando (solo en web): se muestra OpenStreetMap mientras tanto.
  cargando,

  /// Listo para dibujar Google Maps.
  listo,

  /// Falló: se usa OpenStreetMap.
  fallo,
}
