import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/maps_config.dart';
import 'package:iglesias_app/ui/shared/map/coordenada_mapa.dart';
import 'package:iglesias_app/ui/shared/map/mapa_iglesias.dart';
import 'package:iglesias_app/ui/shared/map/mapa_osm.dart';

void main() {
  testWidgets('con el respaldo activo se dibuja OpenStreetMap', (tester) async {
    MapsConfig.activarRespaldoOsm();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapaIglesias(
            marcadores: [],
            centroInicial: CoordenadaMapa(-12.0464, -77.0428),
          ),
        ),
      ),
    );
    expect(find.byType(MapaOsm), findsOneWidget);
  });
}
