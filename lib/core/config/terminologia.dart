import '../../data/models/enums.dart';
import '../../data/models/iglesia_model.dart';

/// Vocabulario visible de cada denominación (solo textos de pantalla).
///
/// Es un bloque reutilizable por las apps: cada app (flavor) obtiene la
/// suya con [Terminologia.para] y las pantallas nunca escriben a mano
/// "Pastor", "Padre", "Misa" o "Culto". Los valores que se guardan en
/// Firestore (`RolGlobal.value`, `TipoActividad.value`, …) NO cambian: aquí
/// solo se decide cómo se muestran.
class Terminologia {
  const Terminologia({
    required this.etiquetaRolUsuario,
    required this.etiquetaRolLider,
    required this.tituloLider,
    required this.etiquetaCampoLider,
    required this.tiposActividad,
    required this.ejemploTituloEvento,
    required this.etiquetaInformada,
    required this.etiquetaInformadaCorta,
    required this.etiquetaAdministrada,
    required this.ejemploCargo,
    required this.ejemploContacto,
    required this.ejemploMinisterio,
  });

  /// Rol `Usuario` en pantalla (ej. 'Usuario / Laicado').
  final String etiquetaRolUsuario;

  /// Rol `Pastor_Padre` en pantalla (ej. 'Padre').
  final String etiquetaRolLider;

  /// Cómo se nombra al líder de una iglesia dentro de una frase
  /// (ej. 'el Padre de la iglesia matriz').
  final String tituloLider;

  /// Etiqueta del campo "líder de la iglesia" del formulario de iglesia.
  final String etiquetaCampoLider;

  /// Tipos de evento que se ofrecen al crear un evento (el primero es el
  /// valor por defecto).
  final List<TipoActividad> tiposActividad;

  /// Texto de ejemplo del campo "Título" del formulario de evento.
  final String ejemploTituloEvento;

  /// Iglesia "Informada" (no verificada) reportada por un usuario.
  final String etiquetaInformada;

  /// Versión corta de [etiquetaInformada] (pin del mapa, subtítulos).
  final String etiquetaInformadaCorta;

  /// Iglesia cuyo reclamo fue aprobado (administrada por su comunidad).
  final String etiquetaAdministrada;

  /// Ejemplo del campo "Cargo" al reclamar una iglesia.
  final String ejemploCargo;

  /// Ejemplo de cómo verificar el reclamo (teléfono, etc.).
  final String ejemploContacto;

  /// Ejemplo del campo "Nombre" al crear un ministerio.
  final String ejemploMinisterio;

  /// Etiqueta fija de OpenStreetMap (origen OSM).
  static const String etiquetaOsm = 'OpenStreetMap';

  /// Etiqueta fija de una iglesia "Verificada".
  static const String etiquetaVerificada = 'Verificada';

  /// App 1 · Católica.
  static const Terminologia catolica = Terminologia(
    etiquetaRolUsuario: 'Usuario / Laicado',
    etiquetaRolLider: 'Padre',
    tituloLider: 'Padre',
    etiquetaCampoLider: 'Padre',
    tiposActividad: [TipoActividad.misa, TipoActividad.reunion],
    ejemploTituloEvento: 'Ej. Misa dominical, Misa de jóvenes',
    etiquetaInformada: 'Informada por el laicado',
    etiquetaInformadaCorta: 'Laicado',
    etiquetaAdministrada: 'Administrada por la parroquia',
    ejemploCargo: 'Ej. Párroco, secretario parroquial',
    ejemploContacto: 'teléfono de la parroquia',
    ejemploMinisterio: 'Ej. Coro parroquial, Pastoral juvenil…',
  );

  /// App 2 · Evangélica.
  static const Terminologia evangelica = Terminologia(
    etiquetaRolUsuario: 'Usuario / Congregación',
    etiquetaRolLider: 'Pastor',
    tituloLider: 'Pastor',
    etiquetaCampoLider: 'Pastor',
    tiposActividad: [TipoActividad.culto, TipoActividad.reunion],
    ejemploTituloEvento: 'Ej. Culto dominical, Culto de jóvenes',
    etiquetaInformada: 'Informada por la congregación',
    etiquetaInformadaCorta: 'Congregación',
    etiquetaAdministrada: 'Administrada por la iglesia',
    ejemploCargo: 'Ej. Pastor, secretario de la iglesia',
    ejemploContacto: 'teléfono de la iglesia',
    ejemploMinisterio: 'Ej. Ministerio de alabanza, Jóvenes…',
  );

  /// App adventista (planificada): datos y textos listos.
  static const Terminologia adventista = Terminologia(
    etiquetaRolUsuario: 'Usuario / Feligresía',
    etiquetaRolLider: 'Pastor',
    tituloLider: 'Pastor',
    etiquetaCampoLider: 'Pastor',
    tiposActividad: [TipoActividad.culto, TipoActividad.reunion],
    ejemploTituloEvento: 'Ej. Culto de sábado, Escuela Sabática',
    etiquetaInformada: 'Informada por la feligresía',
    etiquetaInformadaCorta: 'Feligresía',
    etiquetaAdministrada: 'Administrada por la iglesia',
    ejemploCargo: 'Ej. Pastor, anciano de iglesia',
    ejemploContacto: 'teléfono de la iglesia',
    ejemploMinisterio: 'Ej. Conquistadores, Ministerio joven…',
  );

  /// Textos generales: Apps 3 y 4 y la App 5 (Visión Global).
  static const Terminologia general = Terminologia(
    etiquetaRolUsuario: 'Usuario / Congregación',
    etiquetaRolLider: 'Pastor / Padre',
    tituloLider: 'Pastor/Padre',
    etiquetaCampoLider: 'Pastor / Padre a cargo',
    tiposActividad: TipoActividad.values,
    ejemploTituloEvento: 'Ej. Misa dominical, Culto de jóvenes',
    etiquetaInformada: 'Informada por la congregación',
    etiquetaInformadaCorta: 'Congregación',
    etiquetaAdministrada: 'Administrada por la congregación',
    ejemploCargo: 'Ej. Pastor, Padre, secretario de la iglesia',
    ejemploContacto: 'teléfono de la iglesia',
    ejemploMinisterio: 'Ej. Coro, Ministerio juvenil…',
  );

  /// Vocabulario de la app que muestra solo [denominacion]
  /// (null = todas las denominaciones, App 5).
  static Terminologia para(Denominacion? denominacion) {
    switch (denominacion) {
      case Denominacion.catolica:
        return catolica;
      case Denominacion.evangelica:
        return evangelica;
      case Denominacion.adventista:
        return adventista;
      case Denominacion.testigosJehova:
      case Denominacion.santosUltimosDias:
      case null:
        return general;
    }
  }

  /// Nombre visible de un rol (el resto de roles usa su `label`).
  String etiquetaRol(RolGlobal rol) {
    switch (rol) {
      case RolGlobal.usuario:
        return etiquetaRolUsuario;
      case RolGlobal.pastorPadre:
        return etiquetaRolLider;
      case RolGlobal.coordinador:
      case RolGlobal.adminGeneral:
        return rol.label;
    }
  }

  /// Resumen de los tipos de evento (ej. 'Misa o reunión').
  String get resumenTiposActividad {
    final nombres = [
      for (var i = 0; i < tiposActividad.length; i++)
        i == 0
            ? tiposActividad[i].label
            : tiposActividad[i].label.toLowerCase(),
    ];
    if (nombres.length <= 1) return nombres.join();
    return '${nombres.sublist(0, nombres.length - 1).join(', ')} '
        'o ${nombres.last}';
  }

  /// Procedencia completa: OSM → 'OpenStreetMap'; verificada → 'Verificada';
  /// informada → [etiquetaInformada].
  String procedencia({
    required OrigenIglesia origen,
    required Oficialidad oficialidad,
  }) {
    if (origen == OrigenIglesia.osm) return etiquetaOsm;
    return oficialidad == Oficialidad.verificada
        ? etiquetaVerificada
        : etiquetaInformada;
  }

  /// Estado de administración en texto (sin administrador / reclamo /
  /// administrada según la denominación).
  String estadoAdministracion(EstadoAdministracion e) {
    switch (e) {
      case EstadoAdministracion.sinAdministrador:
        return EstadoAdministracion.sinAdministrador.label;
      case EstadoAdministracion.reclamacionPendiente:
        return EstadoAdministracion.reclamacionPendiente.label;
      case EstadoAdministracion.administrada:
        return etiquetaAdministrada;
    }
  }

  /// Procedencia corta (pin del mapa): OSM → 'OpenStreetMap';
  /// verificada → 'Verificada'; informada → [etiquetaInformadaCorta].
  String procedenciaCortaDe(IglesiaModel i) {
    if (i.esDeOsm) return etiquetaOsm;
    return i.oficialidad == Oficialidad.verificada
        ? etiquetaVerificada
        : etiquetaInformadaCorta;
  }

  /// Procedencia completa de [i].
  String procedenciaDe(IglesiaModel i) =>
      procedencia(origen: i.origen, oficialidad: i.oficialidad);
}
