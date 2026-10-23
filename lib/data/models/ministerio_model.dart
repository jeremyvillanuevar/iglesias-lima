import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class MinisterioModel {
  final String idMinisterio;
  final String nombre;
  final DocumentReference? iglesiaRef; // null si es independiente
  final TipoUbicacionMinisterio tipoUbicacion;
  final GeoPoint? ubicacionPropia; // solo si tipoUbicacion == fisica
  final String? linkVirtual; // (agregado) si es virtual
  final Denominacion?
      denominacion; // (agregado) la de su iglesia matriz o, si es independiente, la elegida/fijada por la app
  final String? pais; // (agregado) RF-3.3, si es independiente
  final String? localidad; // (agregado) RF-3.3, si es independiente
  final DocumentReference
      coordinadorRef; // "Administrador de Ministerio" (RF-3.1)
  final EstadoAprobacion estadoAprobacion;
  final DocumentReference creadoPor; // (agregado)
  final EstadoLogico estadoLogico; // (agregado)
  final DateTime? creadoEn; // (agregado)

  const MinisterioModel({
    required this.idMinisterio,
    required this.nombre,
    this.iglesiaRef,
    required this.tipoUbicacion,
    this.ubicacionPropia,
    this.linkVirtual,
    this.denominacion,
    this.pais,
    this.localidad,
    required this.coordinadorRef,
    required this.estadoAprobacion,
    required this.creadoPor,
    required this.estadoLogico,
    this.creadoEn,
  });

  /// El creador queda como coordinador (Administrador de Ministerio)
  /// automáticamente (RF-3.1) y el ministerio entra Pendiente.
  factory MinisterioModel.nuevo({
    required String idMinisterio,
    required String nombre,
    DocumentReference? iglesiaRef,
    required TipoUbicacionMinisterio tipoUbicacion,
    GeoPoint? ubicacionPropia,
    String? linkVirtual,
    Denominacion? denominacion,
    String? pais,
    String? localidad,
    required DocumentReference creadoPor,
  }) {
    return MinisterioModel(
      idMinisterio: idMinisterio,
      nombre: nombre,
      iglesiaRef: iglesiaRef,
      tipoUbicacion: tipoUbicacion,
      ubicacionPropia: ubicacionPropia,
      linkVirtual: linkVirtual,
      denominacion: denominacion,
      pais: pais,
      localidad: localidad,
      coordinadorRef: creadoPor,
      estadoAprobacion: EstadoAprobacion.pendiente,
      creadoPor: creadoPor,
      estadoLogico: EstadoLogico.activo,
    );
  }

  factory MinisterioModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final denominacion = d['denominacion'];
    return MinisterioModel(
      idMinisterio: doc.id,
      nombre: d['nombre'] as String? ?? '',
      iglesiaRef: d['iglesia_ref'] as DocumentReference?,
      tipoUbicacion: TipoUbicacionMinisterio.fromValue(d['tipo_ubicacion']),
      ubicacionPropia: d['ubicacion_propia'] as GeoPoint?,
      linkVirtual: d['link_virtual'] as String?,
      denominacion:
          denominacion == null ? null : Denominacion.fromValue(denominacion),
      pais: d['pais'] as String?,
      localidad: d['localidad'] as String?,
      coordinadorRef: d['coordinador_ref'] as DocumentReference,
      estadoAprobacion: EstadoAprobacion.fromValue(d['estado_aprobacion']),
      creadoPor: d['creado_por'] as DocumentReference,
      estadoLogico: EstadoLogico.fromValue(d['estado_logico']),
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id_ministerio': idMinisterio,
        'nombre': nombre,
        'iglesia_ref': iglesiaRef,
        'tipo_ubicacion': tipoUbicacion.value,
        'ubicacion_propia': ubicacionPropia,
        'link_virtual': linkVirtual,
        'denominacion': denominacion?.value,
        'pais': pais,
        'localidad': localidad,
        'coordinador_ref': coordinadorRef,
        'estado_aprobacion': estadoAprobacion.value,
        'creado_por': creadoPor,
        'estado_logico': estadoLogico.value,
        'creado_en': creadoEn != null
            ? Timestamp.fromDate(creadoEn!)
            : FieldValue.serverTimestamp(),
      };

  bool get esIndependiente => iglesiaRef == null;
  bool get esPublico =>
      estadoAprobacion == EstadoAprobacion.aprobado &&
      estadoLogico == EstadoLogico.activo;
}
