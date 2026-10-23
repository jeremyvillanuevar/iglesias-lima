import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/terminologia.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:iglesias_app/data/models/iglesia_model.dart';
import 'package:iglesias_app/data/demo/demo_document_reference.dart';

void main() {
  group('etiqueta de procedencia (por denominación)', () {
    for (final t in [
      Terminologia.catolica,
      Terminologia.evangelica,
      Terminologia.adventista,
      Terminologia.general,
    ]) {
      test('${t.etiquetaInformadaCorta}: OSM → OpenStreetMap', () {
        expect(
          t.procedencia(
              origen: OrigenIglesia.osm, oficialidad: Oficialidad.informada),
          Terminologia.etiquetaOsm,
        );
        expect(
          t.estadoAdministracion(EstadoAdministracion.sinAdministrador),
          'Sin administrador',
        );
        expect(
          t.estadoAdministracion(EstadoAdministracion.administrada),
          t.etiquetaAdministrada,
        );
        final p = t.procedencia(
            origen: OrigenIglesia.osm, oficialidad: Oficialidad.informada);
        expect(p, isNot(contains('Informada')));
        expect(p, isNot(contains('Fuente:')));
      });
    }

    test('usuario informada → etiquetaInformada', () {
      expect(
        Terminologia.catolica.procedencia(
            origen: OrigenIglesia.usuario, oficialidad: Oficialidad.informada),
        'Informada por el laicado',
      );
      expect(
        Terminologia.evangelica.procedencia(
            origen: OrigenIglesia.usuario, oficialidad: Oficialidad.informada),
        'Informada por la congregación',
      );
    });
  });

  test('IglesiaModel.desdeOsm legacy → porNombre', () {
    final i = IglesiaModel.desdeOsm(
      osmId: 'node/99',
      nombre: 'X',
      denominacion: Denominacion.catolica,
      latitud: -12,
      longitud: -77,
      pais: 'Perú',
      localidad: 'Lima',
      creadoPor: DemoDocumentReference('users/x'),
      verificacionDenominacion: VerificacionDenominacion.porVerificar,
    );
    expect(i.criterio, CriterioOsm.porNombre);
    expect(i.esDeOsm, isTrue);
    expect(i.sinMarcador, isFalse);
  });

  test('criterio_osm Nombre_Catolico se agrupa como porNombre', () {
    final osm = IglesiaModel.desdeOsm(
      osmId: 'node/11',
      nombre: 'Parroquia San X',
      denominacion: Denominacion.catolica,
      latitud: -12,
      longitud: -77,
      pais: 'Perú',
      localidad: 'Lima',
      creadoPor: DemoDocumentReference('users/a'),
      verificacionDenominacion: VerificacionDenominacion.porVerificar,
      criterioOsm: CriterioOsm.nombreCatolico,
    );
    expect(osm.criterio, CriterioOsm.nombreCatolico);
    expect(osm.criterio?.grupo, CriterioOsm.porNombre);
    expect(CriterioOsm.nombreCatolico.grupo, CriterioOsm.porNombre);
  });

  test('procedenciaCortaDe: OSM / informada / verificada', () {
    const t = Terminologia.evangelica;
    final osm = IglesiaModel.desdeOsm(
      osmId: 'node/1',
      nombre: 'X',
      denominacion: Denominacion.evangelica,
      latitud: -12,
      longitud: -77,
      pais: 'Perú',
      localidad: 'Lima',
      creadoPor: DemoDocumentReference('users/a'),
      verificacionDenominacion: VerificacionDenominacion.confirmadaOsm,
      criterioOsm: CriterioOsm.etiquetaOsm,
    );
    expect(t.procedenciaCortaDe(osm), 'OpenStreetMap');
    expect(t.procedenciaDe(osm), 'OpenStreetMap');
  });

  test('asset católico real: totales y criterios', () {
    final f = File('assets/importacion/iglesias_catolicas_lima_osm.json');
    expect(f.existsSync(), isTrue);
    final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    expect(j['total'], 660);
    expect(j['total_confirmadas'], 323);
    expect(j['total_por_verificar'], 337);
    expect(j['total_sin_marcador'], 166);
    final criterios = <String, int>{};
    for (final i in j['iglesias'] as List) {
      final c = (i as Map)['criterio_osm'] as String;
      criterios[c] = (criterios[c] ?? 0) + 1;
    }
    expect(criterios['Etiqueta_OSM'], 323);
    expect(criterios['Nombre_Catolico'], 171);
    expect(criterios['Sin_Marcador'], 166);
  });
}
