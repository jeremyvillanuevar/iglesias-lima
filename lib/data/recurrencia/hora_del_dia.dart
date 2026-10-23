import '../../core/utils/formato_fechas.dart';

/// Una hora del día (turno), sin depender de Flutter. Ej.: 07:00, 12:00, 17:00.
class HoraDelDia implements Comparable<HoraDelDia> {
  const HoraDelDia(this.hora, this.minuto)
      : assert(hora >= 0 && hora < 24),
        assert(minuto >= 0 && minuto < 60);

  final int hora;
  final int minuto;

  int get minutosDesdeMedianoche => hora * 60 + minuto;

  /// "07:00"
  String get texto => FormatoFechas.horaMinuto(hora, minuto);

  @override
  int compareTo(HoraDelDia other) =>
      minutosDesdeMedianoche.compareTo(other.minutosDesdeMedianoche);

  @override
  bool operator ==(Object other) =>
      other is HoraDelDia && other.hora == hora && other.minuto == minuto;

  @override
  int get hashCode => Object.hash(hora, minuto);

  @override
  String toString() => texto;
}
