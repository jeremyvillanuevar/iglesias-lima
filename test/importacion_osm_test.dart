import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/config/fuente_importacion_osm.dart';
import 'package:iglesias_app/core/di/dependencias.dart';
import 'package:iglesias_app/data/demo/demo_auth_repository.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/data/demo/demo_importacion_iglesias_repository.dart';
import 'package:iglesias_app/data/importacion/lector_importacion_osm.dart';
import 'package:iglesias_app/data/importacion/planificador_importacion.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:iglesias_app/data/models/iglesia_model.dart';
import 'package:iglesias_app/data/repositories/permiso_denegado_exception.dart';
import 'package:iglesias_app/ui/admin/importacion_osm_view_model.dart';
import 'package:iglesias_app/ui/admin/moderacion_view_model.dart';

/// Archivo de prueba en memoria (3 iglesias).
class _BundleDePrueba extends CachingAssetBundle {
  _BundleDePrueba(this.contenido);

  final Map<String, Object?> contenido;

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(jsonEncode(contenido));
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

Map<String, Object?> _archivo({String denominacion = 'Catolica'}) => {
      'atribucion': '© Colaboradores de OpenStreetMap',
      'licencia': 'ODbL 1.0',
      'area': 'Lima Metropolitana y Callao',
      'denominacion': denominacion,
      'iglesias': [
        {
          'osm_id': 'node/1',
          'nombre': 'Parroquia Uno',
          'lat': -12.05,
          'lng': -77.04,
          'direccion': 'Av. Uno 100',
          'distrito': 'Lima',
          'verificacion_denominacion': 'Confirmada_OSM',
        },
        {
          'osm_id': 'way/2',
          'nombre': 'Capilla Dos',
          'lat': -12.1,
          'lng': -77.0
        },
        {
          'osm_id': 'relation/3',
          'nombre': 'Santuario Tres',
          'lat': -12.06,
          'lng': -77.13,
          'distrito': 'Callao'
        },
        // Repetido: se ignora.
        {
          'osm_id': 'way/2',
          'nombre': 'Capilla Dos',
          'lat': -12.1,
          'lng': -77.0
        },
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DemoDataStore store;
  late Dependencias deps;

  setUp(() async {
    store = DemoDataStore(latenciaSimulada: Duration.zero);
    deps = Dependencias.demo(flavor: AppFlavor.catolica, store: store);
    await deps.auth.iniciarSesionConGoogle(); // Admin General en el demo.
  });
  tearDown(() => store.cerrar());

  DemoImportacionIglesiasRepository repo(
          {Map<String, Object?>? archivo, int tamanoLote = 2}) =>
      DemoImportacionIglesiasRepository(
        store,
        deps.auth,
        lector: LectorImportacionOsm(
            bundle: _BundleDePrueba(archivo ?? _archivo())),
        planificador: PlanificadorImportacion(tamanoLote: tamanoLote),
      );

  List<IglesiaModel> importadas() =>
      store.iglesias.value.where((i) => i.origen == OrigenIglesia.osm).toList();

  test('importar dos veces no duplica (idempotente) e informa el avance',
      () async {
    final antes = store.iglesias.value.length;
    final avances = <String>[];
    final r1 = await repo().importarDesdeOsm(
      FuenteImportacionOsm.catolicasLima,
      alProgresar: (h, t) => avances.add('$h/$t'),
    );
    expect(r1.total, 3);
    expect(r1.creadas, 3);
    expect(r1.yaExistian, 0);
    expect(r1.porVerificar, 2); // way/2 y relation/3 (sin el campo).
    expect(avances, ['0/3', '2/3', '3/3']);
    expect(store.iglesias.value.length, antes + 3);

    final r2 =
        await repo().importarDesdeOsm(FuenteImportacionOsm.catolicasLima);
    expect(r2.creadas, 0);
    expect(r2.yaExistian, 3);
    expect(store.iglesias.value.length, antes + 3);
    expect(importadas().map((i) => i.idIglesia).toSet(),
        {'osm_node_1', 'osm_way_2', 'osm_relation_3'});
  });

  test('las iglesias importadas son públicas y "Sin administrador"', () async {
    await repo().importarDesdeOsm(FuenteImportacionOsm.catolicasLima);
    final uno = importadas().firstWhere((i) => i.osmId == 'node/1');
    expect(uno.estadoAprobacion, EstadoAprobacion.aprobado);
    expect(uno.esPublica, isTrue);
    expect(uno.estadoAdministracion, EstadoAdministracion.sinAdministrador);
    expect(uno.admiteReclamo, isTrue);
    expect(uno.liderUidRef, isNull);
    expect(uno.denominacion, Denominacion.catolica);
    expect(uno.direccionTexto, 'Av. Uno 100 – Lima');
    expect(uno.localidad, 'Lima');
    expect(uno.pais, 'Perú');
    // Aparecen en el mapa de la App 1.
    final mapa = await deps.iglesias.observarIglesiasDelMapa().first;
    expect(mapa.map((i) => i.idIglesia), contains('osm_node_1'));
  });

  test('niveles: Confirmada_OSM y Por_Verificar; el admin confirma o descarta',
      () async {
    await repo().importarDesdeOsm(FuenteImportacionOsm.catolicasLima);
    final uno = importadas().firstWhere((i) => i.osmId == 'node/1');
    expect(
        uno.verificacionDenominacion, VerificacionDenominacion.confirmadaOsm);
    expect(uno.porVerificar, isFalse);

    final porVerificar = await deps.iglesias.observarPorVerificar().first;
    expect(porVerificar.map((i) => i.idIglesia).toSet(),
        {'osm_way_2', 'osm_relation_3'});
    // Siguen en el mapa.
    final mapa = await deps.iglesias.observarIglesiasDelMapa().first;
    expect(mapa.map((i) => i.idIglesia), contains('osm_way_2'));

    final vm = ModeracionViewModel(
      authRepository: deps.auth,
      iglesiaRepository: deps.iglesias,
      ministerioRepository: deps.ministerios,
      eventoRepository: deps.eventos,
      reclamoRepository: deps.reclamos,
      terminologia: AppFlavor.catolica.terminologia,
    );
    addTearDown(vm.dispose);
    await pumpEventQueue();
    expect(vm.totalPorVerificar, 2);
    vm.filtrarPorVerificar('santuario');
    expect(vm.porVerificar.map((i) => i.nombre), ['Santuario Tres']);
    vm.filtrarPorVerificar('');

    expect(await vm.confirmarDenominacion('osm_way_2'), isNull);
    expect(await vm.descartarPorVerificar('osm_relation_3'), isNull);
    await pumpEventQueue();
    expect(vm.totalPorVerificar, 0);
    final dos = store.iglesiaPorPath('iglesias/osm_way_2')!;
    expect(
        dos.verificacionDenominacion, VerificacionDenominacion.confirmadaOsm);
    expect(store.iglesiaPorPath('iglesias/osm_relation_3'), isNull);

    // Reimportar no vuelve a crear la descartada.
    final r = await repo().importarDesdeOsm(FuenteImportacionOsm.catolicasLima);
    expect(r.creadas, 0);
    expect(store.iglesiaPorPath('iglesias/osm_relation_3'), isNull);
  });

  test('un Pastor/Padre no ve ni confirma las "por verificar"', () async {
    await repo().importarDesdeOsm(FuenteImportacionOsm.catolicasLima);
    await (deps.auth as DemoAuthRepository)
        .cambiarRolDemo(RolGlobal.pastorPadre);
    expect(await deps.iglesias.observarPorVerificar().first, isEmpty);
    expect(() => deps.iglesias.confirmarDenominacion('osm_way_2'),
        throwsA(isA<PermisoDenegadoException>()));
  });

  test('solo el Administrador General puede importar', () async {
    await (deps.auth as DemoAuthRepository)
        .cambiarRolDemo(RolGlobal.pastorPadre);
    expect(() => repo().importarDesdeOsm(FuenteImportacionOsm.catolicasLima),
        throwsA(isA<PermisoDenegadoException>()));
    expect(importadas(), isEmpty);
  });

  test('rechaza un archivo de otra denominación', () async {
    expect(
      () => repo(archivo: _archivo(denominacion: 'Evangelica'))
          .importarDesdeOsm(FuenteImportacionOsm.catolicasLima),
      throwsFormatException,
    );
  });

  test('el archivo incluido trae las iglesias católicas de Lima', () async {
    final paquete =
        await LectorImportacionOsm().leer(FuenteImportacionOsm.catolicasLima);
    expect(paquete.iglesias.length, greaterThan(400));
    expect(paquete.atribucion, contains('OpenStreetMap'));
    expect(paquete.licencia, contains('ODbL'));
    final confirmadas = paquete.iglesias
        .where((i) => i.verificacion == VerificacionDenominacion.confirmadaOsm);
    expect(confirmadas.length, greaterThan(300));
    expect(paquete.iglesias.length - confirmadas.length, greaterThan(100));
    final ids = paquete.iglesias.map((i) => i.osmId).toSet();
    expect(ids.length, paquete.iglesias.length);
  });

  test('ViewModel: importa con el repositorio de la app y muestra el conteo',
      () async {
    expect(AppFlavor.catolica.fuentesImportacionOsm,
        [FuenteImportacionOsm.catolicasLima]);
    final vm = ImportacionOsmViewModel(
      importacionRepository: repo(),
      fuentes: AppFlavor.catolica.fuentesImportacionOsm,
    );
    addTearDown(vm.dispose);
    await vm.importar();
    expect(vm.error, isNull);
    expect(vm.resultado!.creadas, 3);
    expect(vm.procesadas, 3);
    expect(vm.total, 3);
  });
}
