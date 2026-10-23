import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/di/dependencias.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/ui/admin/moderacion_screen.dart';
import 'package:iglesias_app/ui/admin/moderacion_view_model.dart';
import 'package:iglesias_app/ui/ministerio_form/crear_ministerio_screen.dart';
import 'package:iglesias_app/ui/ministerio_form/crear_ministerio_view_model.dart';

/// Pantallas nuevas de la App 1 (Católica) en Modo Demo.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  late DemoDataStore store;
  late Dependencias deps;

  setUp(() async {
    store = DemoDataStore(latenciaSimulada: Duration.zero);
    deps = Dependencias.demo(flavor: AppFlavor.catolica, store: store);
    await deps.auth.iniciarSesionConGoogle();
  });

  testWidgets('Moderación: pestañas y tarjetas con Aprobar/Rechazar',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => ModeracionViewModel(
          authRepository: deps.auth,
          iglesiaRepository: deps.iglesias,
          ministerioRepository: deps.ministerios,
          eventoRepository: deps.eventos,
          reclamoRepository: deps.reclamos,
          terminologia: AppFlavor.catolica.terminologia,
        ),
        child: const ModeracionScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Iglesias'), findsWidgets);
    expect(find.textContaining('Ministerios'), findsWidgets);
    expect(find.textContaining('Eventos'), findsWidgets);
    expect(find.text('Capilla San José Obrero (ejemplo)'), findsOneWidget);
    expect(find.text('Aprobar'), findsWidgets);
    expect(find.text('Rechazar'), findsWidgets);

    await tester.tap(find.text('Aprobar').first);
    await tester.pumpAndSettle();
    expect(find.text('Capilla San José Obrero (ejemplo)'), findsNothing);
  });

  testWidgets('Nuevo ministerio: denominación fija y valida la iglesia matriz',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => CrearMinisterioViewModel(
          ministerioRepository: deps.ministerios,
          iglesiaRepository: deps.iglesias,
          flavor: AppFlavor.catolica,
        ),
        child: const CrearMinisterioScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo ministerio'), findsOneWidget);
    expect(find.textContaining('Administrador de Ministerio'), findsOneWidget);
    expect(find.text('Católica'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del ministerio *'),
        'Coro juvenil');
    final guardar = find.text('Guardar ministerio');
    await tester.ensureVisible(guardar);
    await tester.tap(guardar);
    await tester.pumpAndSettle();
    expect(
        find.text('Elige la iglesia matriz del ministerio.'), findsOneWidget);
  });
}
