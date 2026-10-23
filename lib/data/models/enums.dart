abstract interface class FirestoreEnum {
  String get value;
  String get label;
}

T enumFromValue<T extends FirestoreEnum>(
    List<T> values, Object? raw, T fallback) {
  for (final e in values) {
    if (e.value == raw) return e;
  }
  return fallback;
}

enum RolGlobal implements FirestoreEnum {
  usuario('Usuario', 'Usuario / Congregación'),
  coordinador('Coordinador', 'Coordinador / Líder'),
  pastorPadre('Pastor_Padre', 'Pastor / Padre'),
  adminGeneral('Admin_General', 'Administrador General');

  const RolGlobal(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static RolGlobal fromValue(Object? raw) =>
      enumFromValue(values, raw, usuario);
}

enum EstadoCuenta implements FirestoreEnum {
  activo('Activo', 'Activo'),
  suspendido('Suspendido', 'Suspendido');

  const EstadoCuenta(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static EstadoCuenta fromValue(Object? raw) =>
      enumFromValue(values, raw, activo);
}

/// Denominaciones del ecosistema. `value` va a Firestore (sin tildes),
/// `label` es el nombre completo en pantalla y `etiquetaCorta` se usa donde
/// hay poco espacio (chips de filtro, pines del mapa).
///
/// Cada app de directorio (Apps 1 a 4) muestra solo una denominación; la
/// App 5 (Visión Global Cristiana) muestra todas (ver `AppFlavor`).
///
/// [adventista] ya está lista para una app propia (planificada, aún sin
/// flavor): hoy solo existen sus datos de importación y la ve la App 5.
/// Las iglesias adventistas no aparecen en la App 2 (Evangélica).
enum Denominacion implements FirestoreEnum {
  catolica('Catolica', 'Católica', 'Católica'),
  evangelica('Evangelica', 'Evangélica', 'Evangélica'),
  testigosJehova('TestigosJehova', 'Testigos de Jehová', 'Testigos de Jehová'),
  santosUltimosDias(
    'SantosUltimosDias',
    'Iglesia de Jesucristo de los Santos de los Últimos Días',
    'IJSUD',
  ),
  adventista(
    'Adventista',
    'Iglesia Adventista del Séptimo Día',
    'IASD',
  );

  const Denominacion(this.value, this.label, this.etiquetaCorta);
  @override
  final String value;
  @override
  final String label;

  /// Nombre corto para chips y pines (ej. 'IJSUD').
  final String etiquetaCorta;

  static Denominacion fromValue(Object? raw) =>
      enumFromValue(values, raw, catolica);
}

/// Tipo de ubicación de una Iglesia (RF-2.1)
enum TipoUbicacion implements FirestoreEnum {
  fisica('Fisica', 'Física'),
  virtual('Virtual', 'Virtual');

  const TipoUbicacion(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static TipoUbicacion fromValue(Object? raw) =>
      enumFromValue(values, raw, fisica);
}

/// Tipo de ubicación de un Ministerio (RF-3.2 y RF-3.3)
enum TipoUbicacionMinisterio implements FirestoreEnum {
  iglesia('Iglesia', 'En su iglesia matriz'),
  fisica('Fisica', 'Ubicación propia'),
  virtual('Virtual', 'Virtual');

  const TipoUbicacionMinisterio(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static TipoUbicacionMinisterio fromValue(Object? raw) =>
      enumFromValue(values, raw, iglesia);
}

/// Estado de moderación. Todo entra Pendiente; un aprobador (Pastor/Padre
/// líder de la iglesia, coordinador del ministerio) o el Admin General lo
/// pasa a Aprobado (público) o Rechazado (no público; solo lo ve su creador).
enum EstadoAprobacion implements FirestoreEnum {
  pendiente('Pendiente', 'Pendiente'),
  aprobado('Aprobado', 'Aprobado'),
  rechazado('Rechazado', 'Rechazado');

  const EstadoAprobacion(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static EstadoAprobacion fromValue(Object? raw) =>
      enumFromValue(values, raw, pendiente);
}

enum Oficialidad implements FirestoreEnum {
  informada('Informada', 'Informada por Laico/Congregación'),
  verificada('Verificada', 'Verificada/Ministrada por la Iglesia');

  const Oficialidad(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static Oficialidad fromValue(Object? raw) =>
      enumFromValue(values, raw, informada);
}

enum EstadoLogico implements FirestoreEnum {
  activo('Activo', 'Activo'),
  eliminado('Eliminado', 'Eliminado');

  const EstadoLogico(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static EstadoLogico fromValue(Object? raw) =>
      enumFromValue(values, raw, activo);
}

enum TipoActividad implements FirestoreEnum {
  misa('Misa', 'Misa'),
  culto('Culto', 'Culto'),
  reunion('Reunion', 'Reunión');

  const TipoActividad(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static TipoActividad fromValue(Object? raw) =>
      enumFromValue(values, raw, reunion);
}

/// Quién administra una iglesia. Las importadas de OpenStreetMap entran
/// "Sin_Administrador" hasta que una parroquia/comunidad la reclame y el
/// Administrador General apruebe el reclamo (pasa a "Administrada").
enum EstadoAdministracion implements FirestoreEnum {
  sinAdministrador('Sin_Administrador', 'Sin administrador'),
  reclamacionPendiente('Reclamacion_Pendiente', 'Reclamo pendiente'),
  administrada('Administrada', 'Administrada');

  const EstadoAdministracion(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static EstadoAdministracion fromValue(Object? raw) =>
      enumFromValue(values, raw, sinAdministrador);
}

/// De dónde vino el registro de una iglesia.
enum OrigenIglesia implements FirestoreEnum {
  usuario('Usuario', 'Registrada por un usuario'),
  osm('OSM', 'Importada de OpenStreetMap');

  const OrigenIglesia(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static OrigenIglesia fromValue(Object? raw) =>
      enumFromValue(values, raw, usuario);
}

/// Qué tan segura es la denominación de una iglesia importada de
/// OpenStreetMap. "Confirmada_OSM": OSM la etiqueta como católica.
/// "Por_Verificar": solo se dedujo por el nombre; el Administrador General
/// la confirma o la descarta en Moderación. Las creadas por usuarios no
/// llevan este dato (null).
enum VerificacionDenominacion implements FirestoreEnum {
  confirmadaOsm('Confirmada_OSM', 'Confirmada'),
  porVerificar('Por_Verificar', 'Por verificar');

  const VerificacionDenominacion(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static VerificacionDenominacion fromValue(Object? raw) =>
      enumFromValue(values, raw, porVerificar);

  /// null si el documento no trae el campo.
  static VerificacionDenominacion? fromValueOrNull(Object? raw) =>
      raw == null ? null : fromValue(raw);
}

/// Por qué una iglesia de OpenStreetMap entró en la importación.
/// "Etiqueta_OSM": OSM la etiqueta con su denominación (nivel A).
/// "Nombre_Catolico" (archivo católico) y "Por_Nombre" (resto de
/// denominaciones): sin etiqueta, pero su nombre marca la denominación.
/// "Sin_Marcador": sin etiqueta ni marca en el nombre; el Administrador
/// General debe revisarla una por una.
enum CriterioOsm implements FirestoreEnum {
  etiquetaOsm('Etiqueta_OSM', 'Etiqueta de OpenStreetMap'),
  nombreCatolico('Nombre_Catolico', 'Por el nombre'),
  porNombre('Por_Nombre', 'Por el nombre'),
  sinMarcador('Sin_Marcador', 'Sin marcador');

  const CriterioOsm(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
  static CriterioOsm fromValue(Object? raw) =>
      enumFromValue(values, raw, sinMarcador);

  /// null si el documento no trae el campo.
  static CriterioOsm? fromValueOrNull(Object? raw) =>
      raw == null ? null : fromValue(raw);

  /// Grupo para filtrar: "Nombre_Catolico" y "Por_Nombre" son lo mismo
  /// (deducida por el nombre); el valor guardado no cambia.
  CriterioOsm get grupo => this == nombreCatolico ? porNombre : this;
}
