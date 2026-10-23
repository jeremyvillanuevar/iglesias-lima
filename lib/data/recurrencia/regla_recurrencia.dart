import 'frecuencia_recurrencia.dart';
import 'hora_del_dia.dart';

/// Lo que el usuario elige en el formulario para repetir un evento.
///
/// Si [frecuencia] no es "ninguna", se termina en [fechaFin] (inclusive)
/// o tras [repeticiones] fechas. Si vienen ambos, manda el que llegue antes.
class ReglaRecurrencia {
  const ReglaRecurrencia({
    required this.fechaInicio,
    required this.turnos,
    this.frecuencia = FrecuenciaRecurrencia.ninguna,
    this.fechaFin,
    this.repeticiones,
  });

  /// Día del primer evento (se ignora la hora; la hora sale de [turnos]).
  final DateTime fechaInicio;

  /// Horas del día en que hay evento (al menos una).
  final List<HoraDelDia> turnos;
  final FrecuenciaRecurrencia frecuencia;
  final DateTime? fechaFin;
  final int? repeticiones;

  bool get seRepite => frecuencia != FrecuenciaRecurrencia.ninguna;
}
