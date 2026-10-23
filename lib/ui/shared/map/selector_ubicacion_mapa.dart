import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/ubicacion_dispositivo.dart';
import 'controlador_mapa.dart';
import 'coordenada_mapa.dart';
import 'mapa_iglesias.dart';
import 'marcador_mapa.dart';

/// Mapa pequeño para marcar una ubicación (iglesia física RF-2.1 o
/// ministerio independiente RF-3.3).
/// Se toca el mapa para poner el pin; también se puede usar el GPS.
class SelectorUbicacionMapa extends StatefulWidget {
  const SelectorUbicacionMapa({
    super.key,
    required this.seleccion,
    required this.onCambio,
    this.errorTexto,
    this.altura = 260,
    this.instruccion = 'Toca el mapa para marcar la iglesia',
  });

  final CoordenadaMapa? seleccion;
  final ValueChanged<CoordenadaMapa> onCambio;
  final String? errorTexto;
  final double altura;

  /// Texto de ayuda que se muestra sobre el mapa.
  final String instruccion;

  @override
  State<SelectorUbicacionMapa> createState() => _SelectorUbicacionMapaState();
}

class _SelectorUbicacionMapaState extends State<SelectorUbicacionMapa> {
  final ControladorMapa _mapa = ControladorMapa();
  bool _ubicando = false;

  Future<void> _usarMiUbicacion() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ubicando = true);
    try {
      final c = await const UbicacionDispositivo().obtener();
      widget.onCambio(c);
      _mapa.moverA(c, zoom: 17);
    } on UbicacionNoDisponible catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('No se pudo obtener tu ubicación ($e).')));
    } finally {
      if (mounted) setState(() => _ubicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sel = widget.seleccion;
    final borde = widget.errorTexto != null
        ? tema.colorScheme.error
        : const Color(0xFFD0D4DC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.altura,
          decoration: BoxDecoration(
            border: Border.all(
                color: borde, width: widget.errorTexto != null ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: MapaIglesias(
                  controlador: _mapa,
                  agrupar: false,
                  centroInicial: sel ??
                      const CoordenadaMapa(
                          AppConstants.limaLatitud, AppConstants.limaLongitud),
                  zoomInicial: sel == null ? 12 : 16,
                  onMapaTap: widget.onCambio,
                  marcadores: [
                    if (sel != null)
                      MarcadorMapa(
                        id: 'seleccion',
                        posicion: sel,
                        titulo: 'Ubicación elegida',
                        color: tema.colorScheme.primary,
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(widget.instruccion,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 28,
                child: FloatingActionButton.small(
                  heroTag: 'selector_mi_ubicacion',
                  tooltip: 'Usar mi ubicación',
                  onPressed: _ubicando ? null : _usarMiUbicacion,
                  child: _ubicando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.errorTexto ??
              (sel == null
                  ? 'Aún no marcaste la ubicación.'
                  : 'Ubicación: $sel'),
          style: TextStyle(
            fontSize: 12,
            color: widget.errorTexto != null ? tema.colorScheme.error : null,
          ),
        ),
      ],
    );
  }
}
