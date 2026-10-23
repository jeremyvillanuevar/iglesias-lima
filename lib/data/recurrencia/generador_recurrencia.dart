import '../../core/constants/app_constants.dart';
import 'frecuencia_recurrencia.dart';
import 'hora_del_dia.dart';
import 'ocurrencia_evento.dart';
import 'regla_recurrencia.dart';
import 'resultado_recurrencia.dart';

/// Convierte una regla de recurrencia en eventos individuales (RF-4.4).
///
/// En el plan gratuito (Spark) no hay Cloud Functions, así que la app genera
/// aquí cada documento de evento y luego los guarda juntos en un "batch".
class GeneradorRecurrencia {
  const GeneradorRecurrencia({
    this.maxOcurrencias = AppConstants.maxOcurrenciasRecurrencia,
    this.mesesVentana = AppConstants.historialMaxMeses,
  });

  /// Tope de documentos que se crean de una sola vez.
  final int maxOcurrencias;

  /// No se generan fechas más allá de estos meses desde la fecha de inicio.
  final int mesesVentana;

  ResultadoRecurrencia generar(ReglaRecurrencia regla) {
    if (regla.turnos.isEmpty) {
      throw ArgumentError('Elige al menos una hora (turno).');
    }
    if (regla.seRepite &&
        regla.fechaFin == null &&
        regla.repeticiones == null) {
      throw ArgumentError('Indica hasta qué fecha o cuántas veces se repite.');
    }
    if (regla.repeticiones != null && regla.repeticiones! < 1) {
      throw ArgumentError('Las repeticiones deben ser al menos 1.');
    }

    final turnos = regla.turnos.toSet().toList()..sort();
    final primerDia = DateTime(
      regla.fechaInicio.year,
      regla.fechaInicio.month,
      regla.fechaInicio.day,
    );
    final limiteVentana =
        DateTime(primerDia.year, primerDia.month + mesesVentana, primerDia.day);
    final usaPatron = regla.seRepite || turnos.length > 1;

    final ocurrencias = <OcurrenciaEvento>[];
    var recortadoPorMaximo = false;
    var recortadoPorVentana = false;

    final totalFechas = regla.seRepite ? (regla.repeticiones ?? 1 << 30) : 1;
    final fechaFin = regla.fechaFin == null
        ? null
        : DateTime(
            regla.fechaFin!.year, regla.fechaFin!.month, regla.fechaFin!.day);

    for (var i = 0; i < totalFechas; i++) {
      // Se suma en días de calendario (evita saltos raros por cambio de hora).
      final dia = DateTime(
        primerDia.year,
        primerDia.month,
        primerDia.day + i * regla.frecuencia.diasEntreFechas,
      );
      if (regla.seRepite && fechaFin != null && dia.isAfter(fechaFin)) break;
      if (!dia.isBefore(limiteVentana)) {
        recortadoPorVentana = true;
        break;
      }

      for (final turno in turnos) {
        if (ocurrencias.length >= maxOcurrencias) {
          recortadoPorMaximo = true;
          break;
        }
        ocurrencias.add(OcurrenciaEvento(
          inicio:
              DateTime(dia.year, dia.month, dia.day, turno.hora, turno.minuto),
          patronRecurrencia: usaPatron ? patron(regla.frecuencia, turno) : null,
        ));
      }
      if (recortadoPorMaximo) break;
      if (!regla.seRepite) break;
    }

    return ResultadoRecurrencia(
      ocurrencias: ocurrencias,
      recortadoPorMaximo: recortadoPorMaximo,
      recortadoPorVentana: recortadoPorVentana,
    );
  }

  /// Texto que se guarda en `patron_recurrencia`, ej. "Semanal_07:00".
  static String patron(FrecuenciaRecurrencia frecuencia, HoraDelDia turno) {
    final prefijo = frecuencia == FrecuenciaRecurrencia.ninguna
        ? 'Turno'
        : frecuencia.prefijoPatron;
    return '${prefijo}_${turno.texto}';
  }
}
