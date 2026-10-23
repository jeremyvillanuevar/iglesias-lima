import '../../data/models/evento_model.dart';

/// Datos que recibe el formulario de evento al abrirse.
class CrearEventoArgs {
  const CrearEventoArgs({this.idIglesia, this.eventoBase});

  /// Iglesia preseleccionada (por ejemplo, desde el Bottom Sheet de un pin).
  final String? idIglesia;

  /// Evento a clonar: el formulario se abre con sus datos (RF-4.4).
  final EventoModel? eventoBase;
}
