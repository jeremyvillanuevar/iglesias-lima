import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class IglesiaModel {
  final String idIglesia;
  final String nombre;
  final Denominacion denominacion;
  final TipoUbicacion tipo;
  final GeoPoint? ubicacion; // obligatoria si es Física
  final String? direccionTexto;
  final String? linkVirtual; // obligatorio si es Virtual
  final String pais; // (agregado) RF-2.1
  final String localidad; // (agregado) RF-2.1, ej. "Lima"
  final EstadoAprobacion estadoAprobacion;
  final Oficialidad oficialidad;
  final String? liderNombreTexto;
  final String? aprobadorNombreTexto; // (agregado) RF-2.2
  final DocumentReference? liderUidRef; // lo asigna el Admin al verificar
  final DocumentReference creadoPor;
  final EstadoLogico estadoLogico; // (agregado) RF-2.5, borrado lógico
  final DateTime? creadoEn; // (agregado)

  /// Quién la administra (las importadas de OSM entran sin administrador).
  final EstadoAdministracion estadoAdministracion;

  /// Formulario de un usuario u OpenStreetMap.
  final OrigenIglesia origen;

  /// Id del elemento de OpenStreetMap (ej. 'way/123'); null si no es de OSM.
  final String? osmId;

  /// Solo en las importadas de OSM: denominación confirmada o por verificar.
  final VerificacionDenominacion? verificacionDenominacion;

  /// Solo en las importadas de OSM: por qué entró (ver [CriterioOsm]).
  /// Las importadas antes de existir el campo lo deducen en [criterio].
  final CriterioOsm? criterioOsm;

  const IglesiaModel({
    required this.idIglesia,
    required this.nombre,
    required this.denominacion,
    required this.tipo,
    this.ubicacion,
    this.direccionTexto,
    this.linkVirtual,
    required this.pais,
    required this.localidad,
    required this.estadoAprobacion,
    required this.oficialidad,
    this.liderNombreTexto,
    this.aprobadorNombreTexto,
    this.liderUidRef,
    required this.creadoPor,
    required this.estadoLogico,
    this.creadoEn,
    this.estadoAdministracion = EstadoAdministracion.sinAdministrador,
    this.origen = OrigenIglesia.usuario,
    this.osmId,
    this.verificacionDenominacion,
    this.criterioOsm,
  });

  /// Id del documento de una iglesia importada de OSM: 'osm_way_123'.
  /// Es fijo, así que importar dos veces nunca duplica.
  static String idDesdeOsm(String osmId) => 'osm_${osmId.replaceAll('/', '_')}';

  /// Iglesia creada desde el formulario: siempre entra Pendiente e Informada (RF-2.3, RF-2.4)
  factory IglesiaModel.nueva({
    required String idIglesia,
    required String nombre,
    required Denominacion denominacion,
    required TipoUbicacion tipo,
    GeoPoint? ubicacion,
    String? direccionTexto,
    String? linkVirtual,
    required String pais,
    required String localidad,
    String? liderNombreTexto,
    String? aprobadorNombreTexto,
    required DocumentReference creadoPor,
  }) {
    return IglesiaModel(
      idIglesia: idIglesia,
      nombre: nombre,
      denominacion: denominacion,
      tipo: tipo,
      ubicacion: tipo == TipoUbicacion.fisica ? ubicacion : null,
      direccionTexto: direccionTexto,
      linkVirtual: tipo == TipoUbicacion.virtual ? linkVirtual : null,
      pais: pais,
      localidad: localidad,
      estadoAprobacion: EstadoAprobacion.pendiente,
      oficialidad: Oficialidad.informada,
      liderNombreTexto: liderNombreTexto,
      aprobadorNombreTexto: aprobadorNombreTexto,
      liderUidRef: null,
      creadoPor: creadoPor,
      estadoLogico: EstadoLogico.activo,
      estadoAdministracion: EstadoAdministracion.sinAdministrador,
      origen: OrigenIglesia.usuario,
    );
  }

  /// Iglesia importada de OpenStreetMap: pública desde el primer momento
  /// (Aprobado + Informada) y sin administrador hasta que la reclamen.
  factory IglesiaModel.desdeOsm({
    required String osmId,
    required String nombre,
    required Denominacion denominacion,
    required double latitud,
    required double longitud,
    String? direccionTexto,
    required String pais,
    required String localidad,
    required DocumentReference creadoPor,
    required VerificacionDenominacion verificacionDenominacion,
    CriterioOsm? criterioOsm,
  }) {
    return IglesiaModel(
      idIglesia: idDesdeOsm(osmId),
      nombre: nombre,
      denominacion: denominacion,
      tipo: TipoUbicacion.fisica,
      ubicacion: GeoPoint(latitud, longitud),
      direccionTexto: direccionTexto,
      pais: pais,
      localidad: localidad,
      estadoAprobacion: EstadoAprobacion.aprobado,
      oficialidad: Oficialidad.informada,
      creadoPor: creadoPor,
      estadoLogico: EstadoLogico.activo,
      estadoAdministracion: EstadoAdministracion.sinAdministrador,
      origen: OrigenIglesia.osm,
      osmId: osmId,
      verificacionDenominacion: verificacionDenominacion,
      criterioOsm: criterioOsm,
    );
  }

  factory IglesiaModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final liderRef = d['lider_uid_ref'] as DocumentReference?;
    return IglesiaModel(
      idIglesia: doc.id,
      nombre: d['nombre'] as String? ?? '',
      denominacion: Denominacion.fromValue(d['denominacion']),
      tipo: TipoUbicacion.fromValue(d['tipo']),
      ubicacion: d['ubicacion'] as GeoPoint?,
      direccionTexto: d['direccion_texto'] as String?,
      linkVirtual: d['link_virtual'] as String?,
      pais: d['pais'] as String? ?? '',
      localidad: d['localidad'] as String? ?? '',
      estadoAprobacion: EstadoAprobacion.fromValue(d['estado_aprobacion']),
      oficialidad: Oficialidad.fromValue(d['oficialidad']),
      liderNombreTexto: d['lider_nombre_texto'] as String?,
      aprobadorNombreTexto: d['aprobador_nombre_texto'] as String?,
      liderUidRef: liderRef,
      creadoPor: d['creado_por'] as DocumentReference,
      estadoLogico: EstadoLogico.fromValue(d['estado_logico']),
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
      // Iglesias guardadas antes de existir este campo: si tienen líder
      // vinculado ya están administradas.
      estadoAdministracion: d['estado_administracion'] == null
          ? (liderRef != null
              ? EstadoAdministracion.administrada
              : EstadoAdministracion.sinAdministrador)
          : EstadoAdministracion.fromValue(d['estado_administracion']),
      origen: OrigenIglesia.fromValue(d['origen']),
      osmId: d['osm_id'] as String?,
      verificacionDenominacion: VerificacionDenominacion.fromValueOrNull(
          d['verificacion_denominacion']),
      criterioOsm: CriterioOsm.fromValueOrNull(d['criterio_osm']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id_iglesia': idIglesia,
        'nombre': nombre,
        'denominacion': denominacion.value,
        'tipo': tipo.value,
        'ubicacion': ubicacion,
        'direccion_texto': direccionTexto,
        'link_virtual': linkVirtual,
        'pais': pais,
        'localidad': localidad,
        'estado_aprobacion': estadoAprobacion.value,
        'oficialidad': oficialidad.value,
        'lider_nombre_texto': liderNombreTexto,
        'aprobador_nombre_texto': aprobadorNombreTexto,
        'lider_uid_ref': liderUidRef,
        'creado_por': creadoPor,
        'estado_logico': estadoLogico.value,
        'creado_en': creadoEn != null
            ? Timestamp.fromDate(creadoEn!)
            : FieldValue.serverTimestamp(),
        'estado_administracion': estadoAdministracion.value,
        'origen': origen.value,
        'osm_id': osmId,
        'verificacion_denominacion': verificacionDenominacion?.value,
        'criterio_osm': criterioOsm?.value,
      };

  /// Viene de OpenStreetMap (y no de un usuario).
  bool get esDeOsm => origen == OrigenIglesia.osm;

  /// Por qué entró de OpenStreetMap; null si no es de OSM. Las importadas
  /// antes de existir `criterio_osm` lo deducen: confirmadas por etiqueta,
  /// el resto por el nombre.
  CriterioOsm? get criterio {
    if (!esDeOsm) return null;
    return criterioOsm ??
        (verificacionDenominacion == VerificacionDenominacion.confirmadaOsm
            ? CriterioOsm.etiquetaOsm
            : CriterioOsm.porNombre);
  }

  /// Importada sin etiqueta ni marca en el nombre (revisar una a una).
  bool get sinMarcador => criterio == CriterioOsm.sinMarcador;

  /// Importada de OSM cuya denominación aún no confirmó el Admin General.
  bool get porVerificar =>
      verificacionDenominacion == VerificacionDenominacion.porVerificar;

  bool get esAdministrada =>
      estadoAdministracion == EstadoAdministracion.administrada;

  /// Se puede pedir administrarla (aún no tiene administrador aprobado).
  bool get admiteReclamo => !esAdministrada && esPublica;

  bool get esFisica => tipo == TipoUbicacion.fisica;
  bool get esPublica =>
      estadoAprobacion == EstadoAprobacion.aprobado &&
      estadoLogico == EstadoLogico.activo;
}
