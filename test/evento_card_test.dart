import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:iglesias_app/data/demo/demo_document_reference.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:iglesias_app/data/models/evento_model.dart';
import 'package:iglesias_app/ui/home_map/widgets/evento_card.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  EventoModel evento({required EstadoAprobacion estado}) => EventoModel(
        idEvento: 'e1',
        tipoActividad: TipoActividad.culto,
        titulo: 'Culto de jóvenes',
        categoria: 'Jóvenes',
        iglesiaRef: DemoDocumentReference('iglesias/i1'),
        fechaHoraInicio: DateTime(2026, 11, 7, 19),
        esRecurrente: true,
        patronRecurrencia: 'Semanal_19:00',
        esVirtual: false,
        estadoAprobacion: estado,
        estadoLogico: EstadoLogico.activo,
        creadoPor: DemoDocumentReference('users/u1'),
      );

  testWidgets('muestra chip Pendiente, recurrencia y el botón Clonar Evento',
      (tester) async {
    var clonado = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EventoCard(
          evento: evento(estado: EstadoAprobacion.pendiente),
          onClonar: () => clonado = true,
        ),
      ),
    ));

    expect(find.text('Culto de jóvenes'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Semanal · 19:00'), findsOneWidget);

    await tester.tap(find.text(EventoCard.textoClonar));
    expect(clonado, isTrue);
  });

  testWidgets('evento aprobado no muestra el chip Pendiente', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: EventoCard(evento: evento(estado: EstadoAprobacion.aprobado))),
    ));
    expect(find.text('Pendiente'), findsNothing);
    expect(find.text(EventoCard.textoClonar), findsNothing);
  });
}
