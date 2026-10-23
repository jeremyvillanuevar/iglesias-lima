import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/config/fuente_importacion_osm.dart';
import 'package:iglesias_app/core/config/terminologia.dart';
import 'package:iglesias_app/core/di/dependencias.dart';
import 'package:iglesias_app/core/theme/app_theme.dart';
import 'package:iglesias_app/core/theme/contraste_color.dart';
import 'package:iglesias_app/data/demo/demo_auth_repository.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/data/demo/demo_datos_semilla.dart';
import 'package:iglesias_app/data/demo/demo_document_reference.dart';
import 'package:iglesias_app/data/models/descarte_osm.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:iglesias_app/data/models/iglesia_model.dart';
import 'package:iglesias_app/ui/home_map/home_map_view_model.dart';
import 'package:iglesias_app/ui/shared/widgets/chip_estado_administracion.dart';
import 'package:iglesias_app/ui/shared/widgets/linea_procedencia.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('identidad App 2', () {
    const f = AppFlavor.evangelica;
    expect(f.nombreApp, 'Iglesias Evangélicas Lima');
    expect(f.applicationId, 'pe.iglesiaslima.evangelica');
    expect(f.denominacionFija, Denominacion.evangelica);
    expect(AppFlavor.entregadas, contains(f));
  });

  test('contraste del azul evangélico', () {
    final c = AppFlavor.evangelica.colorPrimario;
    expect(ContrasteColor.razon(ContrasteColor.textoSobre(c), c),
        greaterThanOrEqualTo(ContrasteColor.minimoTexto));
  });

  test('terminología sin vocabulario católico', () {
    const t = Terminologia.evangelica;
    final texto = [
      t.etiquetaRolUsuario,
      t.etiquetaRolLider,
      t.tituloLider,
      t.etiquetaCampoLider,
      t.ejemploTituloEvento,
      t.etiquetaInformada,
      t.etiquetaInformadaCorta,
      t.etiquetaAdministrada,
      t.ejemploCargo,
      t.ejemploContacto,
      t.ejemploMinisterio,
    ].join(' ');
    expect(
        texto, isNot(contains(RegExp(r'Misa|Padre|Parroqu|parroqu|laicado'))));
  });

  test('fuentes de importación App 2: solo evangélicas', () {
    final f = AppFlavor.evangelica.fuentesImportacionOsm;
    expect(f.map((x) => x.denominacion), [Denominacion.evangelica]);
    expect(
        FuenteImportacionOsm.todas.map((x) => x.denominacion),
        containsAll([
          Denominacion.catolica,
          Denominacion.evangelica,
          Denominacion.adventista,
        ]));
  });

  test('Global incluye Adventista; App 2 no', () {
    expect(AppFlavor.global.denominacionesVisibles,
        contains(Denominacion.adventista));
    expect(AppFlavor.evangelica.admite(Denominacion.adventista), isFalse);
  });

  test('enum Adventista listo', () {
    expect(Denominacion.adventista.value, 'Adventista');
    expect(Denominacion.adventista.etiquetaCorta, 'IASD');
    expect(AppTheme.colorDenominacion(Denominacion.adventista),
        const Color(0xFF00695C));
  });

  group('assets', () {
    test('evangélico: 261 iglesias', () {
      final j = _asset('iglesias_evangelicas_lima_osm.json');
      expect(j['denominacion'], 'Evangelica');
      expect(j['total'], 261);
      expect(j['total_confirmadas'], 78);
      expect(j['total_por_verificar'], 183);
      expect(j['total_sin_marcador'], 0);
      for (final i in j['iglesias'] as List) {
        expect((i as Map)['criterio_osm'], anyOf('Etiqueta_OSM', 'Por_Nombre'));
      }
    });

    test('adventista: 33 iglesias', () {
      final j = _asset('iglesias_adventistas_lima_osm.json');
      expect(j['denominacion'], 'Adventista');
      expect(j['total'], 33);
    });

    test('sin fragmento prohibido en assets', () {
      final frag = String.fromCharCodes([109, 111, 114, 109]);
      for (final n in [
        'iglesias_catolicas_lima_osm.json',
        'iglesias_evangelicas_lima_osm.json',
        'iglesias_adventistas_lima_osm.json',
      ]) {
        final t =
            File('assets/importacion/$n').readAsStringSync().toLowerCase();
        expect(t.contains(frag), isFalse, reason: n);
      }
    });
  });

  group('demo App 2', () {
    late Dependencias deps;
    late DemoDataStore store;

    setUp(() async {
      store = DemoDataStore();
      deps = Dependencias.demo(flavor: AppFlavor.evangelica, store: store);
      await deps.auth.iniciarSesionConGoogle();
    });

    test('mapa muestra solo evangélicas', () async {
      final lista = await deps.iglesias.observarIglesiasDelMapa().first;
      expect(lista, isNotEmpty);
      expect(lista.every((i) => i.denominacion == Denominacion.evangelica),
          isTrue);
    });

    test('obtener catedral/adventista null; sanIsidro no', () async {
      expect(await deps.iglesias.obtener(DemoDatosSemilla.idCatedral), isNull);
      expect(
          await deps.iglesias.obtener(DemoDatosSemilla.idAdventistaJesusMaria),
          isNull);
      expect(
          await deps.iglesias.obtener(DemoDatosSemilla.idSanIsidro), isNotNull);
    });

    test('pin: snippet = procedencia corta', () {
      final vm = HomeMapViewModel(
        iglesiaRepository: deps.iglesias,
        eventoRepository: deps.eventos,
        flavor: AppFlavor.evangelica,
      );
      // Wait for streams
      return Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        final marks = vm.marcadoresPara();
        expect(marks, isNotEmpty);
        for (final m in marks) {
          expect(m.subtitulo,
              anyOf('OpenStreetMap', 'Congregación', 'Verificada'));
          expect(m.subtitulo, isNot(contains('·')));
          expect(m.subtitulo, isNot(contains('administrador')));
          expect(m.subtitulo, isNot(contains('Evangélica')));
        }
        vm.dispose();
      });
    });

    test('descartes por denominación', () async {
      // Admin para poder descartar.
      final auth = deps.auth as DemoAuthRepository;
      await auth.cambiarRolDemo(RolGlobal.adminGeneral);
      final osm = IglesiaModel.desdeOsm(
        osmId: 'node/9001',
        nombre: 'Iglesia Evangélica Demo',
        denominacion: Denominacion.evangelica,
        latitud: -12.05,
        longitud: -77.05,
        pais: 'Perú',
        localidad: 'Lima',
        creadoPor: store.ref('users', 'demo'),
        verificacionDenominacion: VerificacionDenominacion.porVerificar,
        criterioOsm: CriterioOsm.porNombre,
      );
      store.iglesias.add([...store.iglesias.value, osm]);
      await deps.iglesias.descartarImportada(osm.idIglesia);
      expect(
        store.osmDescartadas,
        contains(
            DescarteOsm.idDocumento(Denominacion.evangelica, osm.idIglesia)),
      );
      expect(DescarteOsm.denominacionDe(const {}), Denominacion.catolica);
    });

    testWidgets('línea gris y chips de administración', (tester) async {
      final i = IglesiaModel.desdeOsm(
        osmId: 'node/1',
        nombre: 'Iglesia Test',
        denominacion: Denominacion.evangelica,
        latitud: -12,
        longitud: -77,
        pais: 'Perú',
        localidad: 'Lima',
        creadoPor: DemoDocumentReference('users/demo'),
        verificacionDenominacion: VerificacionDenominacion.confirmadaOsm,
        criterioOsm: CriterioOsm.etiquetaOsm,
      );
      const term = Terminologia.evangelica;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.claro(AppFlavor.evangelica),
        home: Scaffold(
          body: Column(
            children: [
              LineaProcedencia(iglesia: i, terminologia: term),
              ChipEstadoAdministracion(iglesia: i, terminologia: term),
              Text(term.etiquetaInformada),
            ],
          ),
        ),
      ));
      expect(find.text('OpenStreetMap'), findsOneWidget);
      expect(find.text('Sin administrador'), findsOneWidget);
      expect(find.text('Informada por la congregación'), findsOneWidget);
      final estilo = tester.widget<Text>(find.text('OpenStreetMap')).style!;
      expect(estilo.fontWeight, FontWeight.normal);
    });
  });
}

Map<String, dynamic> _asset(String nombre) =>
    jsonDecode(File('assets/importacion/$nombre').readAsStringSync())
        as Map<String, dynamic>;
