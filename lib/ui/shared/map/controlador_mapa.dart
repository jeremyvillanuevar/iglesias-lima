import 'coordenada_mapa.dart';

/// Permite mover la cámara del mapa desde fuera (botón "Mi ubicación",
/// resultados de búsqueda), sin importar qué proveedor de mapa se use.
class ControladorMapa {
  void Function(CoordenadaMapa destino, double? zoom)? _mover;

  /// Lo llama la implementación del mapa cuando ya está lista.
  void vincular(void Function(CoordenadaMapa destino, double? zoom) mover) {
    _mover = mover;
  }

  void desvincular() => _mover = null;

  bool get listo => _mover != null;

  void moverA(CoordenadaMapa destino, {double? zoom}) =>
      _mover?.call(destino, zoom);
}
