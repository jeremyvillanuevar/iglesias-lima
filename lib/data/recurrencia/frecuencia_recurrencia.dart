/// Cada cuánto se repite un evento (RF-4.4).
enum FrecuenciaRecurrencia {
  ninguna('Unico', 'No se repite', 0),
  diaria('Diaria', 'Todos los días', 1),
  semanal('Semanal', 'Cada semana', 7),
  quincenal('Quincenal', 'Cada 15 días (cada 2 semanas)', 14);

  const FrecuenciaRecurrencia(
      this.prefijoPatron, this.label, this.diasEntreFechas);

  /// Se usa para armar `patron_recurrencia`, ej. "Semanal_07:00".
  final String prefijoPatron;
  final String label;

  /// Días entre una fecha y la siguiente (0 = no se repite).
  final int diasEntreFechas;
}
