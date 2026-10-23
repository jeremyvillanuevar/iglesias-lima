import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:iglesias_app/app.dart';
import 'package:iglesias_app/core/di/dependencias.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:iglesias_app/ui/home_map/widgets/evento_card.dart';

/// Recorrido completo en Modo Demo: lista -> Bottom Sheet -> historial ->
/// Clonar Evento (pide login) -> formulario prellenado -> guardar con recurrencia.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('flujo demo: ver eventos, historial, clonar con recurrencia',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    final store = DemoDataStore(latenciaSimulada: Duration.zero);
    await tester
        .pumpWidget(IglesiasApp(dependencias: Dependencias.demo(store: store)));
    await tester.pump(const Duration(milliseconds: 200));

    // Lista de iglesias -> Catedral
    await tester.tap(find.byTooltip('Ver lista de iglesias'));
    await tester.pumpAndSettle();
    // App 1 (Católica): solo las 6 parroquias católicas aprobadas.
    expect(find.text('6 iglesias'), findsOneWidget);
    await tester.tap(find.text('Catedral Basílica de Lima (ejemplo)'));
    await tester.pumpAndSettle();

    // Bottom Sheet con eventos próximos
    expect(find.text('Próximos 30 días'), findsOneWidget);
    expect(find.text('Misa de mediodía'), findsWidgets);

    // Historial / Vencidos
    await tester.tap(find.text('Historial / Vencidos'));
    await tester.pumpAndSettle();
    expect(find.text('Misa por el aniversario de Lima'), findsOneWidget);

    // Volver a próximos y clonar el primer evento -> pide login
    await tester.tap(find.text('Próximos 30 días'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(EventoCard.textoClonar).first);
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsWidgets);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'jeremy@ejemplo.pe');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    // Formulario prellenado (clonado)
    expect(find.text('Clonar evento'), findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, 'Misa de mediodía'), findsOneWidget);

    // Repetir semanalmente 3 veces
    await tester.ensureVisible(find.text('No se repite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No se repite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cada semana').last);
    await tester.pumpAndSettle();

    final campoVeces = find.widgetWithText(TextFormField, 'Número de fechas');
    await tester.ensureVisible(campoVeces);
    await tester.pumpAndSettle();
    await tester.enterText(campoVeces, '3');
    await tester.pumpAndSettle();
    expect(find.textContaining('Se crearán 3 eventos'), findsOneWidget);

    final guardar = find.text('Crear 3 eventos');
    await tester.ensureVisible(guardar);
    await tester.pumpAndSettle();
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    // De vuelta en el Bottom Sheet: aparecen los nuevos eventos Pendientes
    expect(find.text('Se crearon 3 eventos. Quedan Pendientes de aprobación.'),
        findsOneWidget);
    final pendientes = store.eventos.value.where((e) =>
        e.titulo == 'Misa de mediodía' &&
        e.estadoAprobacion == EstadoAprobacion.pendiente &&
        e.patronRecurrencia == 'Semanal_12:00');
    expect(pendientes, hasLength(3));
  });
}
