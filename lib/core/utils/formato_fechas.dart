import 'package:intl/intl.dart';

/// Formatos de fecha y hora en español (Perú).
abstract final class FormatoFechas {
  static const String _locale = 'es';

  /// "dom. 25 oct."
  static String diaCorto(DateTime f) =>
      DateFormat('EEE d MMM', _locale).format(f);

  /// "domingo, 25 de octubre de 2026"
  static String diaLargo(DateTime f) =>
      DateFormat("EEEE, d 'de' MMMM 'de' y", _locale).format(f);

  /// "25/10/2026"
  static String fecha(DateTime f) =>
      DateFormat('dd/MM/yyyy', _locale).format(f);

  /// "07:00"
  static String hora(DateTime f) => DateFormat('HH:mm', _locale).format(f);

  /// "dom. 25 oct. · 07:00"
  static String diaYHora(DateTime f) => '${diaCorto(f)} · ${hora(f)}';

  /// "07:00" a partir de hora y minuto.
  static String horaMinuto(int hora, int minuto) =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
}
