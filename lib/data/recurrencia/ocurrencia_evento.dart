/// Una fecha y hora concreta en la que se creará un documento de evento.
class OcurrenciaEvento {
  const OcurrenciaEvento({required this.inicio, this.patronRecurrencia});

  final DateTime inicio;

  /// Ej. "Semanal_07:00". null = evento único (es_recurrente = false).
  final String? patronRecurrencia;

  bool get esRecurrente => patronRecurrencia != null;
}
