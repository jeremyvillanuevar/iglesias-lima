import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/di/dependencias.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/data/demo/demo_datos_semilla.dart';
import 'package:iglesias_app/data/models/enums.dart';

/// Filtrado por denominación según la app (flavor).
void main() {
  late DemoDataStore store;

  setUp(() => store = DemoDataStore(latenciaSimulada: Duration.zero));
  tearDown(() => store.cerrar());

  group('App 1 – Católica', () {
    late Dependencias deps;
    setUp(() =>
        deps = Dependencias.demo(flavor: AppFlavor.catolica, store: store));

    test('el mapa solo muestra iglesias católicas (al menos 5)', () async {
      final lista = await deps.iglesias.observarIglesiasDelMapa().first;
      expect(lista.length, greaterThanOrEqualTo(5));
      expect(
          lista.every((i) => i.denominacion == Denominacion.catolica), isTrue);
    });

    test('los eventos de 30 días son solo de iglesias católicas', () async {
      final iglesias = await deps.iglesias.observarIglesiasDelMapa().first;
      final ids = iglesias.map((i) => i.idIglesia).toSet();
      final eventos = await deps.eventos.observarProximos30Dias().first;
      expect(eventos, isNotEmpty);
      for (final e in eventos.where((e) => e.iglesiaRef != null)) {
        expect(ids, contains(e.iglesiaRef!.id));
      }
      for (final e in eventos.where((e) => e.iglesiaRef == null)) {
        final m = await deps.ministerios.obtener(e.ministerioRef!.id);
        expect(m!.denominacion, Denominacion.catolica);
      }
      // Al menos 5 parroquias distintas tienen actividad próxima.
      final conEventos = eventos
          .where((e) => e.iglesiaRef != null)
          .map((e) => e.iglesiaRef!.id)
          .toSet();
      expect(conEventos.length, greaterThanOrEqualTo(5));
    });

    test('una iglesia de otra denominación no se puede abrir por id', () async {
      expect(await deps.iglesias.obtener(DemoDatosSemilla.idSanIsidro), isNull);
      expect(await deps.iglesias.obtener(DemoDatosSemilla.idLaMolina), isNull);
      expect(
          await deps.iglesias.obtener(DemoDatosSemilla.idCatedral), isNotNull);
      final eventos = await deps.eventos
          .observarEventosDeIglesia(DemoDatosSemilla.idSanIsidro)
          .first;
      expect(eventos, isEmpty);
    });

    test('no deja registrar una iglesia de otra denominación', () async {
      await deps.auth.iniciarSesionConGoogle();
      expect(
        () => deps.iglesias.crearIglesia(
          nombre: 'Otra',
          denominacion: Denominacion.evangelica,
          tipo: TipoUbicacion.fisica,
          ubicacion: const GeoPoint(-12.1, -77.0),
        ),
        throwsArgumentError,
      );
    });

    test(
        'ministerio: hereda Católica y rechaza una matriz de otra denominación',
        () async {
      await deps.auth.iniciarSesionConGoogle();
      final id = await deps.ministerios.crearMinisterio(
        nombre: 'Rosario de los martes',
        tipoUbicacion: TipoUbicacionMinisterio.virtual,
        linkVirtual: 'https://meet.example.org/rosario',
      );
      final m = await deps.ministerios.obtener(id);
      expect(m!.denominacion, Denominacion.catolica);

      expect(
        () => deps.ministerios.crearMinisterio(
          nombre: 'Grupo X',
          tipoUbicacion: TipoUbicacionMinisterio.iglesia,
          idIglesia: DemoDatosSemilla.idSanIsidro,
        ),
        throwsArgumentError,
      );
      expect(
        () => deps.ministerios.crearMinisterio(
          nombre: 'Grupo Y',
          tipoUbicacion: TipoUbicacionMinisterio.virtual,
          linkVirtual: 'https://example.org',
          denominacion: Denominacion.evangelica,
        ),
        throwsArgumentError,
      );
    });
  });

  test('App 5 – Visión Global muestra todas las denominaciones', () async {
    final deps = Dependencias.demo(flavor: AppFlavor.global, store: store);
    final lista = await deps.iglesias.observarIglesiasDelMapa().first;
    expect(
        lista.map((i) => i.denominacion).toSet(), Denominacion.values.toSet());
  });

  test('cada flavor de una denominación solo ve la suya', () async {
    for (final flavor in AppFlavor.values.where((f) => f.esDenominacionUnica)) {
      final deps = Dependencias.demo(flavor: flavor, store: store);
      final lista = await deps.iglesias.observarIglesiasDelMapa().first;
      expect(lista, isNotEmpty, reason: flavor.nombreApp);
      expect(
          lista.every((i) => i.denominacion == flavor.denominacionFija), isTrue,
          reason: flavor.nombreApp);
    }
  });
}
