import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class EventoModel {
  final String idEvento;
  final TipoActividad tipoActividad;
  final String titulo;
  final String categoria; // ej. "Jóvenes", "Ayuno", "Matrimonios"
  final String? descripcion;
  final DocumentReference? iglesiaRef;
  final DocumentReference? ministerioRef;
  final DateTime fechaHoraInicio;
  final DateTime? fechaHoraFin;
  final bool esRecurrente; // true si nació de una recurrencia (RF-4.4)
  final String? patronRecurrencia; // ej. "Semanal_07:00"
  final bool esVirtual; // (agregado) RF-4.3
  final String? linkVirtual; // (agregado) obligatorio si esVirtual
  final String? imagenUrl; // (agregado) RF-4.3
  final EstadoAprobacion estadoAprobacion;
  final EstadoLogico estadoLogico;
  final DocumentReference creadoPor;
  final DateTime? creadoEn; // (agregado)

  const EventoModel({
    required this.idEvento,
    required this.tipoActividad,
    required this.titulo,
    required this.categoria,
    this.descripcion,
    this.iglesiaRef,
    this.ministerioRef,
    required this.fechaHoraInicio,
    this.fechaHoraFin,
    required this.esRecurrente,
    this.patronRecurrencia,
    required this.esVirtual,
    this.linkVirtual,
    this.imagenUrl,
    required this.estadoAprobacion,
    required this.estadoLogico,
    required this.creadoPor,
    this.creadoEn,
  });

  /// Evento creado desde el formulario: siempre entra Pendiente (RF-4.5)
  factory EventoModel.nuevo({
    required String idEvento,
    required TipoActividad tipoActividad,
    required String titulo,
    required String categoria,
    String? descripcion,
    DocumentReference? iglesiaRef,
    DocumentReference? ministerioRef,
    required DateTime fechaHoraInicio,
    DateTime? fechaHoraFin,
    bool esVirtual = false,
    String? linkVirtual,
    String? imagenUrl,
    bool esRecurrente = false,
    String? patronRecurrencia,
    required DocumentReference creadoPor,
  }) {
    return EventoModel(
      idEvento: idEvento,
      tipoActividad: tipoActividad,
      titulo: titulo,
      categoria: categoria,
      descripcion: descripcion,
      iglesiaRef: iglesiaRef,
      ministerioRef: ministerioRef,
      fechaHoraInicio: fechaHoraInicio,
      fechaHoraFin: fechaHoraFin,
      esRecurrente: esRecurrente,
      patronRecurrencia: esRecurrente ? patronRecurrencia : null,
      esVirtual: esVirtual,
      linkVirtual: esVirtual ? linkVirtual : null,
      imagenUrl: imagenUrl,
      estadoAprobacion: EstadoAprobacion.pendiente,
      estadoLogico: EstadoLogico.activo,
      creadoPor: creadoPor,
    );
  }

  factory EventoModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return EventoModel(
      idEvento: doc.id,
      tipoActividad: TipoActividad.fromValue(d['tipo_actividad']),
      titulo: d['titulo'] as String? ?? '',
      categoria: d['categoria'] as String? ?? '',
      descripcion: d['descripcion'] as String?,
      iglesiaRef: d['iglesia_ref'] as DocumentReference?,
      ministerioRef: d['ministerio_ref'] as DocumentReference?,
      fechaHoraInicio: (d['fecha_hora_inicio'] as Timestamp).toDate(),
      fechaHoraFin: (d['fecha_hora_fin'] as Timestamp?)?.toDate(),
      esRecurrente: d['es_recurrente'] as bool? ?? false,
      patronRecurrencia: d['patron_recurrencia'] as String?,
      esVirtual: d['es_virtual'] as bool? ?? false,
      linkVirtual: d['link_virtual'] as String?,
      imagenUrl: d['imagen_url'] as String?,
      estadoAprobacion: EstadoAprobacion.fromValue(d['estado_aprobacion']),
      estadoLogico: EstadoLogico.fromValue(d['estado_logico']),
      creadoPor: d['creado_por'] as DocumentReference,
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id_evento': idEvento,
        'tipo_actividad': tipoActividad.value,
        'titulo': titulo,
        'categoria': categoria,
        'descripcion': descripcion,
        'iglesia_ref': iglesiaRef,
        'ministerio_ref': ministerioRef,
        'fecha_hora_inicio': Timestamp.fromDate(fechaHoraInicio),
        'fecha_hora_fin':
            fechaHoraFin != null ? Timestamp.fromDate(fechaHoraFin!) : null,
        'es_recurrente': esRecurrente,
        'patron_recurrencia': patronRecurrencia,
        'es_virtual': esVirtual,
        'link_virtual': linkVirtual,
        'imagen_url': imagenUrl,
        'estado_aprobacion': estadoAprobacion.value,
        'estado_logico': estadoLogico.value,
        'creado_por': creadoPor,
        'creado_en': creadoEn != null
            ? Timestamp.fromDate(creadoEn!)
            : FieldValue.serverTimestamp(),
      };

  bool get yaPaso =>
      fechaHoraInicio.isBefore(DateTime.now()); // RF-5.3 historial
}
