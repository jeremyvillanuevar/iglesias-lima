import 'ocurrencia_evento.dart';

/// Resultado de expandir una [ReglaRecurrencia] en fechas concretas.
class ResultadoRecurrencia {
  const ResultadoRecurrencia({
    required this.ocurrencias,
    required this.recortadoPorMaximo,
    required this.recortadoPorVentana,
  });

  final List<OcurrenciaEvento> ocurrencias;

  /// true si se alcanzó el máximo de eventos por creación.
  final bool recortadoPorMaximo;

  /// true si alguna fecha caía más allá de la ventana de 16 meses.
  final bool recortadoPorVentana;

  bool get fueRecortado => recortadoPorMaximo || recortadoPorVentana;
  int get cantidad => ocurrencias.length;
}
