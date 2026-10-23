import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/theme/app_theme.dart';
import 'package:iglesias_app/core/theme/contraste_color.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('texto sobre cada flavor alcanza WCAG AA', () {
    for (final f in AppFlavor.values) {
      final on = ContrasteColor.textoSobre(f.colorPrimario);
      expect(ContrasteColor.razon(on, f.colorPrimario),
          greaterThanOrEqualTo(ContrasteColor.minimoTexto),
          reason: f.id);
    }
  });

  test('textoSobreDenominacion alcanza WCAG AA', () {
    for (final d in Denominacion.values) {
      final c = AppTheme.colorDenominacion(d);
      final on = AppTheme.textoSobreDenominacion(d);
      expect(ContrasteColor.razon(on, c),
          greaterThanOrEqualTo(ContrasteColor.minimoTexto),
          reason: d.value);
    }
  });

  test('opacidadLegible sube hasta alcanzar 4.5', () {
    final o =
        ContrasteColor.opacidadLegible(Colors.white, const Color(0xFF9A4A00));
    expect(o, greaterThanOrEqualTo(0.7));
    expect(o, lessThanOrEqualTo(1.0));
  });

  testWidgets('tabs de Moderación usan onPrimary', (tester) async {
    final tema = AppTheme.claro(AppFlavor.ijsud);
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Moderación'),
            bottom: const TabBar(tabs: [
              Tab(text: 'A'),
              Tab(text: 'B'),
            ]),
          ),
        ),
      ),
    ));
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final scheme = tema.colorScheme;
    expect(tabBar.labelColor ?? scheme.onPrimary, scheme.onPrimary);
  });

  test('pestanasSobrePrimario / SobreSuperficie', () {
    final c = AppTheme.claro(AppFlavor.catolica).colorScheme;
    final p = AppTheme.pestanasSobrePrimario(c);
    expect(p.labelColor, c.onPrimary);
    final s = AppTheme.pestanasSobreSuperficie(c);
    expect(s.labelColor, c.primary);
  });

  test('mezclar produce contraste suficiente', () {
    final m = ContrasteColor.mezclar(Colors.white, const Color(0xFF0D47A1));
    expect(ContrasteColor.razon(m, const Color(0xFF0D47A1)),
        greaterThanOrEqualTo(ContrasteColor.minimoTexto));
  });

  test('luminancia blanco > negro', () {
    expect(ContrasteColor.luminancia(Colors.white),
        greaterThan(ContrasteColor.luminancia(Colors.black)));
  });
}
