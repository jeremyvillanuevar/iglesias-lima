import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Pedido de un usuario para administrar una iglesia que aún no tiene
/// administrador (colección `solicitudes_reclamo`).
///
/// El id es fijo, '<id_iglesia>_<uid>': cada usuario tiene como máximo una
/// solicitud por iglesia. La iglesia NO pasa a ser administrada hasta que el
/// Administrador General la aprueba.
class SolicitudReclamoModel {
  final String idSolicitud;
  final String idIglesia;
  final DocumentReference iglesiaRef;
  final String nombreIglesia;
  final Denominacion denominacion;
  final String uidSolicitante;
  final DocumentReference solicitanteRef;
  final String nombreSolicitante;
  final String emailSolicitante;

  /// Cargo en la iglesia (ej. 'Párroco', 'Secretaria parroquial').
  final String cargo;
  final String? mensaje;

  /// Pendiente → Aprobado o Rechazado.
  final EstadoAprobacion estado;
  final DateTime? creadoEn;
  final DocumentReference? resueltoPor;
  final DateTime? resueltoEn;

  const SolicitudReclamoModel({
    required this.idSolicitud,
    required this.idIglesia,
    required this.iglesiaRef,
    required this.nombreIglesia,
    required this.denominacion,
    required this.uidSolicitante,
    required this.solicitanteRef,
    required this.nombreSolicitante,
    required this.emailSolicitante,
    required this.cargo,
    this.mensaje,
    required this.estado,
    this.creadoEn,
    this.resueltoPor,
    this.resueltoEn,
  });

  /// Id del documento de la solicitud de [uid] sobre [idIglesia].
  static String idPara({required String idIglesia, required String uid}) =>
      '${idIglesia}_$uid';

  /// Solicitud nueva (siempre Pendiente).
  factory SolicitudReclamoModel.nueva({
    required String idIglesia,
    required DocumentReference iglesiaRef,
    required String nombreIglesia,
    required Denominacion denominacion,
    required String uidSolicitante,
    required DocumentReference solicitanteRef,
    required String nombreSolicitante,
    required String emailSolicitante,
    required String cargo,
    String? mensaje,
  }) {
    return SolicitudReclamoModel(
      idSolicitud: idPara(idIglesia: idIglesia, uid: uidSolicitante),
      idIglesia: idIglesia,
      iglesiaRef: iglesiaRef,
      nombreIglesia: nombreIglesia,
      denominacion: denominacion,
      uidSolicitante: uidSolicitante,
      solicitanteRef: solicitanteRef,
      nombreSolicitante: nombreSolicitante,
      emailSolicitante: emailSolicitante,
      cargo: cargo,
      mensaje: mensaje,
      estado: EstadoAprobacion.pendiente,
    );
  }

  factory SolicitudReclamoModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return SolicitudReclamoModel(
      idSolicitud: doc.id,
      idIglesia: d['id_iglesia'] as String? ?? '',
      iglesiaRef: d['iglesia_ref'] as DocumentReference,
      nombreIglesia: d['nombre_iglesia'] as String? ?? '',
      denominacion: Denominacion.fromValue(d['denominacion']),
      uidSolicitante: d['uid_solicitante'] as String? ?? '',
      solicitanteRef: d['solicitante_ref'] as DocumentReference,
      nombreSolicitante: d['nombre_solicitante'] as String? ?? '',
      emailSolicitante: d['email_solicitante'] as String? ?? '',
      cargo: d['cargo'] as String? ?? '',
      mensaje: d['mensaje'] as String?,
      estado: EstadoAprobacion.fromValue(d['estado']),
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
      resueltoPor: d['resuelto_por'] as DocumentReference?,
      resueltoEn: (d['resuelto_en'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id_solicitud': idSolicitud,
        'id_iglesia': idIglesia,
        'iglesia_ref': iglesiaRef,
        'nombre_iglesia': nombreIglesia,
        'denominacion': denominacion.value,
        'uid_solicitante': uidSolicitante,
        'solicitante_ref': solicitanteRef,
        'nombre_solicitante': nombreSolicitante,
        'email_solicitante': emailSolicitante,
        'cargo': cargo,
        'mensaje': mensaje,
        'estado': estado.value,
        'creado_en': creadoEn != null
            ? Timestamp.fromDate(creadoEn!)
            : FieldValue.serverTimestamp(),
        'resuelto_por': resueltoPor,
        'resuelto_en':
            resueltoEn != null ? Timestamp.fromDate(resueltoEn!) : null,
      };

  bool get estaPendiente => estado == EstadoAprobacion.pendiente;

  /// Copia con otro estado (al aprobar o rechazar).
  SolicitudReclamoModel resuelta({
    required EstadoAprobacion estado,
    required DocumentReference resueltoPor,
    required DateTime resueltoEn,
  }) {
    return SolicitudReclamoModel(
      idSolicitud: idSolicitud,
      idIglesia: idIglesia,
      iglesiaRef: iglesiaRef,
      nombreIglesia: nombreIglesia,
      denominacion: denominacion,
      uidSolicitante: uidSolicitante,
      solicitanteRef: solicitanteRef,
      nombreSolicitante: nombreSolicitante,
      emailSolicitante: emailSolicitante,
      cargo: cargo,
      mensaje: mensaje,
      estado: estado,
      creadoEn: creadoEn,
      resueltoPor: resueltoPor,
      resueltoEn: resueltoEn,
    );
  }
}
