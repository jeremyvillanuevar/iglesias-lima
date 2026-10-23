import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/data/recurrencia/frecuencia_recurrencia.dart';
import 'package:iglesias_app/data/recurrencia/generador_recurrencia.dart';
import 'package:iglesias_app/data/recurrencia/hora_del_dia.dart';
import 'package:iglesias_app/data/recurrencia/regla_recurrencia.dart';

void main() {
  const generador = GeneradorRecurrencia();
  final inicio = DateTime(2026, 11, 1); // domingo

  group('GeneradorRecurrencia', () {
    test('evento único con una hora: 1 ocurrencia, no recurrente', () {
      final r = generador.generar(ReglaRecurrencia(
        fechaInicio: inicio,
        turnos: const [HoraDelDia(8, 0)],
      ));
      expect(r.cantidad, 1);
      expect(r.ocurrencias.single.inicio, DateTime(2026, 11, 1, 8));
      expect(r.ocurrencias.single.esRecurrente, isFalse);
      expect(r.fueRecortado, isFalse);
    });

    test('semanal x4 con turnos 7:00 y 12:00 -> 8 eventos con patrón', () {
      final r = generador.generar(ReglaRecurrencia(
        fechaInicio: inicio,
        turnos: const [HoraDelDia(12, 0), HoraDelDia(7, 0)],
        frecuencia: FrecuenciaRecurrencia.semanal,
        repeticiones: 4,
      ));
      expect(r.cantidad, 8);
      expect(r.ocurrencias.first.inicio, DateTime(2026, 11, 1, 7));
      expect(r.ocurrencias.first.patronRecurrencia, 'Semanal_07:00');
      expect(r.ocurrencias[1].patronRecurrencia, 'Semanal_12:00');
      expect(r.ocurrencias.last.inicio, DateTime(2026, 11, 22, 12));
      expect(r.ocurrencias.every((o) => o.esRecurrente), isTrue);
    });

    test('diaria hasta una fecha (inclusive)', () {
      final r = generador.generar(ReglaRecurrencia(
        fechaInicio: inicio,
        turnos: const [HoraDelDia(6, 30)],
        frecuencia: FrecuenciaRecurrencia.diaria,
        fechaFin: DateTime(2026, 11, 5),
      ));
      expect(r.cantidad, 5);
      expect(r.ocurrencias.last.inicio, DateTime(2026, 11, 5, 6, 30));
      expect(r.ocurrencias.first.patronRecurrencia, 'Diaria_06:30');
    });

    test('quincenal salta 14 días', () {
      final r = generador.generar(ReglaRecurrencia(
        fechaInicio: inicio,
        turnos: const [HoraDelDia(19, 0)],
        frecuencia: FrecuenciaRecurrencia.quincenal,
        repeticiones: 3,
      ));
      expect(r.ocurrencias.map((o) => o.inicio.day), [1, 15, 29]);
    });

    test('tope de 60 ocurrencias: 3 turnos diarios por 30 días se recorta', () {
      final r = generador.generar(ReglaRecurrencia(
        fechaInicio: inicio,
        turnos: const [HoraDelDia(7, 0), HoraDelDia(12, 0), HoraDelDia(17, 0)],
        frecuencia: FrecuenciaRecurrencia.diaria,
        repeticiones: 30,
      ));
      expect(r.cantidad, 60);
      expect(r.recortadoPorMaximo, isTrue);
    });

    test('no pasa de la ventana de 16 meses', () {
      // Sin el tope de 60 para comprobar solo la ventana.
      const sinTope = GeneradorRecurrencia(maxOcurrencias: 1000);
      final r = sinTope.generar(ReglaRecurrencia(
        fechaInicio: inicio,
        turnos: const [HoraDelDia(10, 0)],
        frecuencia: FrecuenciaRecurrencia.semanal,
        fechaFin: DateTime(2030, 1, 1),
      ));
      final limite = DateTime(2028, 3, 1); // 1/11/2026 + 16 meses
      expect(r.recortadoPorVentana, isTrue);
      expect(r.recortadoPorMaximo, isFalse);
      expect(r.cantidad, 70);
      expect(r.ocurrencias.every((o) => o.inicio.isBefore(limite)), isTrue);
      expect(
          r.ocurrencias.last.inicio
              .add(const Duration(days: 7))
              .isAfter(limite),
          isTrue);
    });

    test('varios turnos sin repetición: patrón "Turno_HH:mm"', () {
      final r = generador.generar(ReglaRecurrencia(
        fechaInicio: inicio,
        turnos: const [HoraDelDia(7, 0), HoraDelDia(17, 0)],
      ));
      expect(r.cantidad, 2);
      expect(r.ocurrencias.map((o) => o.patronRecurrencia),
          ['Turno_07:00', 'Turno_17:00']);
    });

    test('errores: sin turnos o repetición sin fin', () {
      expect(
        () => generador
            .generar(ReglaRecurrencia(fechaInicio: inicio, turnos: const [])),
        throwsArgumentError,
      );
      expect(
        () => generador.generar(ReglaRecurrencia(
          fechaInicio: inicio,
          turnos: const [HoraDelDia(7, 0)],
          frecuencia: FrecuenciaRecurrencia.semanal,
        )),
        throwsArgumentError,
      );
    });
  });
}
