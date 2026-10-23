import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;

import '../models/enums.dart';
import '../models/evento_model.dart';
import '../models/iglesia_model.dart';
import '../models/ministerio_model.dart';
import 'demo_document_reference.dart';

/// Datos de EJEMPLO para el Modo Demo. Los nombres llevan "(ejemplo)" y los
/// horarios son ilustrativos: no son horarios oficiales de ninguna iglesia.
///
/// Las fechas se calculan a partir de "hoy", así siempre hay eventos en los
/// próximos 30 días y algunos en el historial.
class DemoDatosSemilla {
  DemoDatosSemilla({DateTime? ahora}) : _ahora = ahora ?? DateTime.now();

  final DateTime _ahora;

  /// Dueño de los elementos Pendientes de ejemplo. Al iniciar sesión en el
  /// Modo Demo, estos elementos pasan a ser del usuario que entró, para que
  /// pueda ver cómo luce algo "Pendiente".
  static const String pathCreadorSemilla = 'users/demo-creador-ejemplo';

  /// Usuario "oficial" que publicó los datos aprobados de ejemplo.
  static const String pathAdminSemilla = 'users/demo-admin-ejemplo';

  /// Pastor/Padre (líder) de algunas iglesias de ejemplo. Al iniciar sesión
  /// en el Modo Demo, el usuario que entra pasa a ser ese líder (aprobador).
  static const String pathPastorSemilla = 'users/demo-pastor-ejemplo';

  /// Otro fiel de ejemplo que propuso elementos Pendientes: sirven para
  /// probar Aprobar / Rechazar en la pantalla de Moderación.
  static const String pathLaicoSemilla = 'users/demo-laico-ejemplo';

  static const String idCatedral = 'demo-catedral-lima';
  static const String idMiraflores = 'demo-parroquia-miraflores';
  static const String idSanIsidro = 'demo-evangelica-san-isidro';
  static const String idSjl = 'demo-salon-reino-sjl';
  static const String idLaMolina = 'demo-capilla-la-molina';
  static const String idAdventistaJesusMaria = 'demo-adventista-jesus-maria';
  static const String idVirtualPendiente = 'demo-comunidad-virtual';

  // Más parroquias católicas (App 1) en distintos distritos.
  static const String idBarranco = 'demo-parroquia-barranco';
  static const String idLince = 'demo-parroquia-lince';
  static const String idSurco = 'demo-parroquia-surco';
  static const String idSmp = 'demo-parroquia-smp';

  /// Capilla católica Pendiente propuesta por otro usuario (para moderar).
  static const String idCapillaPendiente = 'demo-capilla-comas-pendiente';

  static const String idMinCoro = 'demo-ministerio-coro-catedral';
  static const String idMinPastoralJuvenil = 'demo-ministerio-pastoral-juvenil';
  static const String idMinRosarioVirtual = 'demo-ministerio-rosario-virtual';
  static const String idMinOracionSurquillo =
      'demo-ministerio-oracion-surquillo';

  final _admin = DemoDocumentReference(pathAdminSemilla);
  final _creadorSemilla = DemoDocumentReference(pathCreadorSemilla);
  final _pastor = DemoDocumentReference(pathPastorSemilla);
  final _laico = DemoDocumentReference(pathLaicoSemilla);
  int _contadorEventos = 0;

  // ------------------------------------------------------------ IGLESIAS --
  List<IglesiaModel> iglesias() => [
        _iglesia(
          id: idCatedral,
          nombre: 'Catedral Basílica de Lima (ejemplo)',
          denominacion: Denominacion.catolica,
          lat: -12.04588,
          lng: -77.02986,
          direccion: 'Plaza Mayor, Jr. Carabaya s/n – Cercado de Lima',
          lider: 'Párroco de la Catedral (ejemplo)',
          oficialidad: Oficialidad.verificada,
          conLiderVinculado: true,
        ),
        _iglesia(
          id: idMiraflores,
          nombre: 'Parroquia Virgen Milagrosa (ejemplo)',
          denominacion: Denominacion.catolica,
          lat: -12.12146,
          lng: -77.02968,
          direccion: 'Frente al Parque Kennedy – Miraflores',
          lider: 'P. Juan Pérez (ejemplo)',
          conLiderVinculado: true,
        ),
        _iglesia(
          id: idBarranco,
          nombre: 'Parroquia San Pedro de Barranco (ejemplo)',
          denominacion: Denominacion.catolica,
          lat: -12.14920,
          lng: -77.02180,
          direccion: 'Frente al Parque Municipal – Barranco',
          lider: 'P. Miguel Torres (ejemplo)',
        ),
        _iglesia(
          id: idLince,
          nombre: 'Parroquia Santa Rosa de Lince (ejemplo)',
          denominacion: Denominacion.catolica,
          lat: -12.08480,
          lng: -77.03500,
          direccion: 'Av. Arequipa (altura cuadra 20) – Lince',
          lider: 'P. Luis Huamán (ejemplo)',
        ),
        _iglesia(
          id: idSurco,
          nombre: 'Parroquia Nuestra Señora del Carmen (ejemplo)',
          denominacion: Denominacion.catolica,
          lat: -12.14600,
          lng: -76.99300,
          direccion: 'Cerca al Parque de la Amistad – Santiago de Surco',
          lider: 'P. Andrés Salazar (ejemplo)',
        ),
        _iglesia(
          id: idSmp,
          nombre: 'Parroquia San Martín de Porres (ejemplo)',
          denominacion: Denominacion.catolica,
          lat: -12.02800,
          lng: -77.06200,
          direccion: 'Av. Perú (altura cuadra 30) – San Martín de Porres',
          lider: 'P. José Quispe (ejemplo)',
        ),
        _iglesia(
          id: idSanIsidro,
          nombre: 'Iglesia Evangélica Pueblo de Dios (ejemplo)',
          denominacion: Denominacion.evangelica,
          lat: -12.09620,
          lng: -77.03580,
          direccion: 'Av. Javier Prado Oeste (altura cuadra 7) – San Isidro',
          lider: 'Pastor Carlos Ramírez (ejemplo)',
        ),
        _iglesia(
          id: idSjl,
          nombre: 'Salón del Reino de los Testigos de Jehová (ejemplo)',
          denominacion: Denominacion.testigosJehova,
          lat: -11.98290,
          lng: -77.00590,
          direccion:
              'Av. Próceres de la Independencia – San Juan de Lurigancho',
          lider: 'Superintendente de la congregación (ejemplo)',
        ),
        _iglesia(
          id: idLaMolina,
          nombre:
              'Capilla de La Iglesia de Jesucristo de los Santos de los Últimos Días (ejemplo)',
          denominacion: Denominacion.santosUltimosDias,
          lat: -12.08180,
          lng: -76.94170,
          direccion: 'Av. La Molina (cerca al óvalo) – La Molina',
          lider: 'Obispo del barrio (ejemplo)',
        ),
        _iglesia(
          id: idAdventistaJesusMaria,
          nombre: 'Iglesia Adventista del Séptimo Día (ejemplo)',
          denominacion: Denominacion.adventista,
          lat: -12.07150,
          lng: -77.04380,
          direccion: 'Av. Brasil – Jesús María',
          lider: 'Pastor de distrito (ejemplo)',
        ),
        // Pendiente y virtual: solo la ve su creador (RF-2.4).
        IglesiaModel(
          idIglesia: idVirtualPendiente,
          nombre: 'Comunidad Virtual de Oración Lima (ejemplo)',
          denominacion: Denominacion.evangelica,
          tipo: TipoUbicacion.virtual,
          linkVirtual: 'https://meet.google.com/',
          pais: 'Perú',
          localidad: 'Lima',
          estadoAprobacion: EstadoAprobacion.pendiente,
          oficialidad: Oficialidad.informada,
          liderNombreTexto: 'Hna. Rosa Quispe (ejemplo)',
          aprobadorNombreTexto: 'Pastor Carlos Ramírez (ejemplo)',
          creadoPor: _creadorSemilla,
          estadoLogico: EstadoLogico.activo,
          creadoEn: _ahora.subtract(const Duration(days: 2)),
        ),
        // Pendiente propuesta por OTRO usuario, con líder vinculado: sirve
        // para probar Aprobar / Rechazar como Pastor/Padre o Admin General.
        IglesiaModel(
          idIglesia: idCapillaPendiente,
          nombre: 'Capilla San José Obrero (ejemplo)',
          denominacion: Denominacion.catolica,
          tipo: TipoUbicacion.fisica,
          ubicacion: const GeoPoint(-11.94570, -77.04870),
          direccionTexto: 'Av. Túpac Amaru (altura km 12) – Comas',
          pais: 'Perú',
          localidad: 'Lima',
          estadoAprobacion: EstadoAprobacion.pendiente,
          oficialidad: Oficialidad.informada,
          liderNombreTexto: 'P. Juan Pérez (ejemplo)',
          aprobadorNombreTexto: 'P. Juan Pérez (ejemplo)',
          liderUidRef: _pastor,
          creadoPor: _laico,
          estadoLogico: EstadoLogico.activo,
          creadoEn: _ahora.subtract(const Duration(days: 1)),
          estadoAdministracion: EstadoAdministracion.administrada,
        ),
      ];

  // --------------------------------------------------------- MINISTERIOS --
  List<MinisterioModel> ministerios() => [
        MinisterioModel(
          idMinisterio: idMinCoro,
          nombre: 'Coro Polifónico de la Catedral (ejemplo)',
          iglesiaRef: DemoDocumentReference('iglesias/$idCatedral'),
          tipoUbicacion: TipoUbicacionMinisterio.iglesia,
          denominacion: Denominacion.catolica,
          coordinadorRef: _admin,
          estadoAprobacion: EstadoAprobacion.aprobado,
          creadoPor: _admin,
          estadoLogico: EstadoLogico.activo,
          creadoEn: _ahora.subtract(const Duration(days: 200)),
        ),
        MinisterioModel(
          idMinisterio: idMinRosarioVirtual,
          nombre: 'Rosario en Línea Lima (ejemplo)',
          tipoUbicacion: TipoUbicacionMinisterio.virtual,
          linkVirtual: 'https://www.youtube.com/',
          denominacion: Denominacion.catolica,
          coordinadorRef: _admin,
          estadoAprobacion: EstadoAprobacion.aprobado,
          creadoPor: _admin,
          estadoLogico: EstadoLogico.activo,
          creadoEn: _ahora.subtract(const Duration(days: 90)),
        ),
        // Pendientes propuestos por otro usuario (para moderar).
        MinisterioModel(
          idMinisterio: idMinPastoralJuvenil,
          nombre: 'Pastoral Juvenil Virgen Milagrosa (ejemplo)',
          iglesiaRef: DemoDocumentReference('iglesias/$idMiraflores'),
          tipoUbicacion: TipoUbicacionMinisterio.iglesia,
          denominacion: Denominacion.catolica,
          coordinadorRef: _laico,
          estadoAprobacion: EstadoAprobacion.pendiente,
          creadoPor: _laico,
          estadoLogico: EstadoLogico.activo,
          creadoEn: _ahora.subtract(const Duration(days: 3)),
        ),
        MinisterioModel(
          idMinisterio: idMinOracionSurquillo,
          nombre: 'Grupo de Oración San Benito – Surquillo (ejemplo)',
          tipoUbicacion: TipoUbicacionMinisterio.fisica,
          ubicacionPropia: const GeoPoint(-12.11250, -77.01900),
          denominacion: Denominacion.catolica,
          pais: 'Perú',
          localidad: 'Lima',
          coordinadorRef: _laico,
          estadoAprobacion: EstadoAprobacion.pendiente,
          creadoPor: _laico,
          estadoLogico: EstadoLogico.activo,
          creadoEn: _ahora.subtract(const Duration(days: 2)),
        ),
      ];

  // ------------------------------------------------------------- EVENTOS --
  List<EventoModel> eventos() {
    final lista = <EventoModel>[];

    // Catedral (Cercado)
    for (var s = 0; s < 4; s++) {
      for (final hora in [8, 11]) {
        lista.add(_evento(idCatedral, TipoActividad.misa, 'Misa dominical',
            'General', _proximo(DateTime.sunday, s, hora),
            patron: 'Semanal_${_dos(hora)}:00',
            descripcion: 'Santa Misa del domingo con coro.'));
      }
    }
    for (var d = 1; d <= 5; d++) {
      lista.add(_evento(idCatedral, TipoActividad.misa, 'Misa de mediodía',
          'General', _dia(d, 12),
          patron: 'Diaria_12:00'));
    }
    lista.add(_evento(
        idCatedral,
        TipoActividad.reunion,
        'Hora Santa – Adoración y Oración',
        'Oración',
        _proximo(DateTime.thursday, 0, 19)));
    lista.addAll([
      _evento(idCatedral, TipoActividad.misa, 'Misa por el aniversario de Lima',
          'General', _dia(-4, 10)),
      _evento(idCatedral, TipoActividad.reunion, 'Retiro de Jóvenes', 'Jóvenes',
          _dia(-45, 9)),
      _evento(idCatedral, TipoActividad.misa, 'Misa de Acción de Gracias',
          'General', _dia(-120, 18)),
    ]);

    // Miraflores
    for (var s = 0; s < 4; s++) {
      lista.add(_evento(idMiraflores, TipoActividad.misa, 'Misa Juvenil',
          'Jóvenes', _proximo(DateTime.saturday, s, 18),
          patron: 'Semanal_18:00'));
    }
    for (var s = 0; s < 3; s++) {
      lista.add(_evento(idMiraflores, TipoActividad.reunion,
          'Catequesis para niños', 'Niños', _proximo(DateTime.sunday, s, 10),
          patron: 'Semanal_10:00'));
    }
    lista.add(_evento(idMiraflores, TipoActividad.reunion,
        'Retiro de Matrimonios', 'Matrimonios', _dia(12, 9),
        pendiente: true,
        descripcion: 'Ejemplo de evento PENDIENTE: solo lo ve su creador.'));
    lista.addAll([
      _evento(idMiraflores, TipoActividad.misa, 'Misa por las familias',
          'Matrimonios', _dia(-10, 19)),
      _evento(idMiraflores, TipoActividad.reunion, 'Bautizos comunitarios',
          'Niños', _dia(-200, 11)),
    ]);

    // San Isidro (evangélica)
    for (var s = 0; s < 4; s++) {
      lista.add(_evento(idSanIsidro, TipoActividad.culto, 'Culto dominical',
          'Alabanza', _proximo(DateTime.sunday, s, 10),
          patron: 'Semanal_10:00'));
    }
    for (var s = 0; s < 4; s++) {
      lista.add(_evento(
          idSanIsidro,
          TipoActividad.culto,
          'Culto de oración en línea',
          'Oración',
          _proximo(DateTime.wednesday, s, 20),
          patron: 'Semanal_20:00',
          virtual: 'https://www.youtube.com/',
          descripcion: 'Transmisión en vivo por YouTube.'));
    }
    lista.add(_evento(idSanIsidro, TipoActividad.reunion, 'Estudio bíblico',
        'Estudio Bíblico', _proximo(DateTime.thursday, 0, 19, minuto: 30)));
    lista.add(_evento(idSanIsidro, TipoActividad.reunion,
        'Ayuno congregacional', 'Ayuno', _dia(9, 6)));
    lista.addAll([
      _evento(idSanIsidro, TipoActividad.culto, 'Culto de santa cena',
          'General', _dia(-7, 10)),
      _evento(idSanIsidro, TipoActividad.reunion, 'Campaña de servicio social',
          'Servicio Social', _dia(-60, 8)),
      _evento(idSanIsidro, TipoActividad.reunion, 'Retiro juvenil en Chosica',
          'Retiro', _dia(-300, 7)),
    ]);

    // San Juan de Lurigancho (Testigos de Jehová)
    for (var s = 0; s < 4; s++) {
      lista.add(_evento(idSjl, TipoActividad.reunion, 'Reunión de entre semana',
          'Estudio Bíblico', _proximo(DateTime.tuesday, s, 19, minuto: 30),
          patron: 'Semanal_19:30'));
      lista.add(_evento(
          idSjl,
          TipoActividad.reunion,
          'Discurso público y estudio de La Atalaya',
          'General',
          _proximo(DateTime.sunday, s, 10),
          patron: 'Semanal_10:00'));
    }
    lista.addAll([
      _evento(idSjl, TipoActividad.reunion, 'Reunión de entre semana',
          'Estudio Bíblico', _dia(-14, 19, minuto: 30)),
      _evento(idSjl, TipoActividad.reunion, 'Asamblea de circuito', 'General',
          _dia(-90, 9)),
    ]);

    // Barranco
    for (var s = 0; s < 4; s++) {
      lista.add(_evento(idBarranco, TipoActividad.misa, 'Misa dominical',
          'General', _proximo(DateTime.sunday, s, 9),
          patron: 'Semanal_09:00'));
    }
    lista.add(_evento(
        idBarranco,
        TipoActividad.reunion,
        'Grupo de oración de matrimonios',
        'Matrimonios',
        _proximo(DateTime.friday, 0, 20)));
    lista.addAll([
      _evento(idBarranco, TipoActividad.misa, 'Misa de fiesta patronal',
          'General', _dia(-30, 11)),
      _evento(idBarranco, TipoActividad.reunion, 'Jornada de servicio social',
          'Servicio Social', _dia(-100, 8)),
    ]);

    // Lince
    for (var d = 1; d <= 6; d++) {
      lista.add(_evento(idLince, TipoActividad.misa, 'Misa de la mañana',
          'General', _dia(d, 7),
          patron: 'Diaria_07:00'));
    }
    for (var s = 0; s < 3; s++) {
      lista.add(_evento(
          idLince,
          TipoActividad.reunion,
          'Adoración al Santísimo',
          'Oración',
          _proximo(DateTime.thursday, s, 18),
          patron: 'Semanal_18:00'));
    }
    lista.add(_evento(idLince, TipoActividad.misa,
        'Misa en honor a Santa Rosa de Lima', 'General', _dia(-50, 10)));

    // Santiago de Surco
    for (var s = 0; s < 4; s++) {
      lista.add(_evento(idSurco, TipoActividad.misa, 'Misa de familias',
          'Matrimonios', _proximo(DateTime.sunday, s, 11),
          patron: 'Semanal_11:00'));
    }
    lista.add(_evento(idSurco, TipoActividad.reunion,
        'Retiro de Cuaresma para jóvenes', 'Retiro', _dia(18, 8)));
    lista.add(_evento(
        idSurco,
        TipoActividad.reunion,
        'Estudio bíblico parroquial',
        'Estudio Bíblico',
        _proximo(DateTime.tuesday, 0, 19, minuto: 30)));
    lista.add(_evento(idSurco, TipoActividad.misa, 'Misa de Primera Comunión',
        'Niños', _dia(-75, 10)));

    // San Martín de Porres
    for (var s = 0; s < 4; s++) {
      lista.add(_evento(idSmp, TipoActividad.misa, 'Misa dominical', 'General',
          _proximo(DateTime.sunday, s, 18),
          patron: 'Semanal_18:00'));
    }
    lista.add(_evento(idSmp, TipoActividad.reunion, 'Olla común solidaria',
        'Servicio Social', _dia(10, 12)));
    lista.add(_evento(
        idSmp, TipoActividad.reunion, 'Ayuno y oración', 'Ayuno', _dia(-5, 7)));

    // Pendientes propuestos por OTRO usuario (para Aprobar / Rechazar).
    lista.add(_evento(idCatedral, TipoActividad.reunion,
        'Vigilia de oración por las vocaciones', 'Oración', _dia(6, 20),
        pendiente: true,
        deOtroUsuario: true,
        descripcion: 'Propuesto por un fiel; espera aprobación del párroco.'));
    lista.add(_evento(idMiraflores, TipoActividad.reunion,
        'Charla prematrimonial', 'Matrimonios', _dia(8, 19),
        pendiente: true, deOtroUsuario: true));

    // La Molina (Iglesia de Jesucristo de los Santos de los Últimos Días)
    for (var s = 0; s < 4; s++) {
      lista.add(_evento(idLaMolina, TipoActividad.reunion,
          'Reunión sacramental', 'General', _proximo(DateTime.sunday, s, 9),
          patron: 'Semanal_09:00'));
    }
    for (var s = 0; s < 2; s++) {
      lista.add(_evento(
          idLaMolina,
          TipoActividad.reunion,
          'Actividad de jóvenes',
          'Jóvenes',
          _proximo(DateTime.wednesday, s, 19),
          patron: 'Quincenal_19:00'));
    }
    lista.add(_evento(idLaMolina, TipoActividad.reunion,
        'Proyecto de servicio comunitario', 'Servicio Social', _dia(15, 9)));
    lista.addAll([
      _evento(idLaMolina, TipoActividad.reunion, 'Noche de hogar familiar',
          'Matrimonios', _dia(-21, 19)),
      _evento(idLaMolina, TipoActividad.reunion, 'Conferencia de estaca',
          'General', _dia(-150, 10)),
    ]);

    // Comunidad virtual pendiente
    lista.add(_evento(idVirtualPendiente, TipoActividad.reunion,
        'Oración de madrugada en línea', 'Oración', _dia(3, 5),
        pendiente: true, virtual: 'https://meet.google.com/'));

    return lista;
  }

  // ------------------------------------------------------------ Internos --
  IglesiaModel _iglesia({
    required String id,
    required String nombre,
    required Denominacion denominacion,
    required double lat,
    required double lng,
    required String direccion,
    required String lider,
    Oficialidad oficialidad = Oficialidad.informada,
    bool conLiderVinculado = false,
  }) {
    return IglesiaModel(
      idIglesia: id,
      nombre: nombre,
      denominacion: denominacion,
      tipo: TipoUbicacion.fisica,
      ubicacion: GeoPoint(lat, lng),
      direccionTexto: direccion,
      pais: 'Perú',
      localidad: 'Lima',
      estadoAprobacion: EstadoAprobacion.aprobado,
      oficialidad: oficialidad,
      liderNombreTexto: lider,
      aprobadorNombreTexto: lider,
      liderUidRef: conLiderVinculado ? _pastor : null,
      creadoPor: _admin,
      estadoLogico: EstadoLogico.activo,
      creadoEn: _ahora.subtract(const Duration(days: 400)),
      // Sin líder vinculado = nadie la administra todavía: se puede reclamar.
      estadoAdministracion: conLiderVinculado
          ? EstadoAdministracion.administrada
          : EstadoAdministracion.sinAdministrador,
    );
  }

  EventoModel _evento(
    String idIglesia,
    TipoActividad tipo,
    String titulo,
    String categoria,
    DateTime inicio, {
    String? patron,
    String? virtual,
    String? descripcion,
    bool pendiente = false,
    bool deOtroUsuario = false,
  }) {
    _contadorEventos++;
    return EventoModel(
      idEvento: 'demo-evento-$_contadorEventos',
      tipoActividad: tipo,
      titulo: titulo,
      categoria: categoria,
      descripcion: descripcion,
      iglesiaRef: DemoDocumentReference('iglesias/$idIglesia'),
      fechaHoraInicio: inicio,
      fechaHoraFin: inicio.add(const Duration(hours: 1, minutes: 30)),
      esRecurrente: patron != null,
      patronRecurrencia: patron,
      esVirtual: virtual != null,
      linkVirtual: virtual,
      estadoAprobacion:
          pendiente ? EstadoAprobacion.pendiente : EstadoAprobacion.aprobado,
      estadoLogico: EstadoLogico.activo,
      creadoPor:
          deOtroUsuario ? _laico : (pendiente ? _creadorSemilla : _admin),
      creadoEn: _ahora.subtract(const Duration(days: 30)),
    );
  }

  /// Día relativo a hoy (negativo = pasado) a la hora indicada.
  DateTime _dia(int dias, int hora, {int minuto = 0}) =>
      DateTime(_ahora.year, _ahora.month, _ahora.day + dias, hora, minuto);

  /// Próximo [diaSemana] (desde mañana) + [semanas] semanas.
  DateTime _proximo(int diaSemana, int semanas, int hora, {int minuto = 0}) {
    var diferencia = (diaSemana - _ahora.weekday) % 7;
    if (diferencia == 0) diferencia = 7;
    return _dia(diferencia + semanas * 7, hora, minuto: minuto);
  }

  String _dos(int n) => n.toString().padLeft(2, '0');
}
