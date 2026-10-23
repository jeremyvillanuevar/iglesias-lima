import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:iglesias_app/app.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/di/dependencias.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/ui/shared/widgets/banner_modo_demo.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('la app arranca en Modo Demo con banner, buscador y botón Crear',
      (tester) async {
    final deps = Dependencias.demo(
      motivo: 'prueba',
      store: DemoDataStore(latenciaSimulada: Duration.zero),
    );
    await tester.pumpWidget(IglesiasApp(dependencias: deps));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(BannerModoDemo.textoPara(AppFlavor.catolica)),
        findsOneWidget);
    expect(find.text('Buscar iglesia, distrito o evento…'), findsOneWidget);
    expect(find.text('Crear'), findsOneWidget);
    // App 1: sin chips de denominación (la app es solo católica).
    expect(find.text('Evangélica'), findsNothing);
    expect(find.text('IJSUD'), findsNothing);

    // Buscar por distrito muestra la iglesia de ejemplo de Miraflores.
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'miraflores');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Parroquia Virgen Milagrosa (ejemplo)'), findsWidgets);
  });
}
