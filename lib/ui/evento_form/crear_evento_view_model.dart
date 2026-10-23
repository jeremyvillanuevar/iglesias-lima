import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/terminologia.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/enums.dart';
import '../../data/models/evento_model.dart';
import '../../data/models/iglesia_model.dart';
import '../../data/recurrencia/frecuencia_recurrencia.dart';
import '../../data/recurrencia/generador_recurrencia.dart';
import '../../data/recurrencia/hora_del_dia.dart';
import '../../data/recurrencia/ocurrencia_evento.dart';
import '../../data/recurrencia/regla_recurrencia.dart';
import '../../data/recurrencia/resultado_recurrencia.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/evento_repository.dart';
import '../../data/repositories/iglesia_repository.dart';

/// Estado del formulario de evento (RF-4.1 a RF-4.5), con recurrencia
/// (diaria/semanal/quincenal), varios turnos al día y clonación (RF-4.4).
class CrearEventoViewModel extends ChangeNotifier {
  CrearEventoViewModel({
    required EventoRepository eventoRepository,
    required IglesiaRepository iglesiaRepository,
    required this.terminologia,
    String? idIglesiaInicial,
    this.eventoBase,
    GeneradorRecurrencia generador = const GeneradorRecurrencia(),
    DateTime Function()? reloj,
  })  : _eventos = eventoRepository,
        _iglesiasRepo = iglesiaRepository,
        _generador = generador,
        _reloj = reloj ?? DateTime.now,
        _tipoActividad = terminologia.tiposActividad.first {
    _idIglesia = eventoBase?.iglesiaRef?.id ?? idIglesiaInicial;
    _prellenar();
    _sub = _iglesiasRepo.observarIglesiasDelMapa().listen(
      (lista) {
        _iglesias = [...lista]..sort((a, b) => a.nombre.compareTo(b.nombre));
        _cargandoIglesias = false;
        _sincronizarVirtualSegunIglesia();
        notifyListeners();
      },
      onError: (Object e) {
        _cargandoIglesias = false;
        _error = 'No se pudieron cargar las iglesias: $e';
        notifyListeners();
      },
    );
  }

  final EventoRepository _eventos;
  final IglesiaRepository _iglesiasRepo;
  final GeneradorRecurrencia _generador;
  final DateTime Function() _reloj;
  StreamSubscription<List<IglesiaModel>>? _sub;

  /// Vocabulario de la app (tipos de evento y textos de ejemplo).
  final Terminologia terminologia;

  /// Evento que se está clonando (null = evento nuevo).
  final EventoModel? eventoBase;

  /// Horas rápidas sugeridas (turnos típicos 7 am / 12 m / 5 pm).
  static const List<HoraDelDia> turnosRapidos = [
    HoraDelDia(7, 0),
    HoraDelDia(12, 0),
    HoraDelDia(17, 0),
    HoraDelDia(19, 0),
  ];

  /// Duraciones que se ofrecen en el formulario (null = sin hora de fin).
  static const List<Duration?> duraciones = [
    null,
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 1, minutes: 30),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
  ];

  // ---------- Estado ----------
  List<IglesiaModel> _iglesias = const [];
  bool _cargandoIglesias = true;
  String? _idIglesia;
  TipoActividad _tipoActividad;
  String? _categoria;
  late DateTime _fecha;
  final Set<HoraDelDia> _turnos = {};
  Duration? _duracion = const Duration(hours: 1);
  bool _esVirtual = false;
  FrecuenciaRecurrencia _frecuencia = FrecuenciaRecurrencia.ninguna;
  bool _terminaPorFecha = false;
  late DateTime _fechaFin;
  int _repeticiones = 4;
  bool _guardando = false;
  String? _error;

  // Textos iniciales para los campos (al clonar).
  String tituloInicial = '';
  String descripcionInicial = '';
  String linkInicial = '';
  String imagenInicial = '';

  // ---------- Getters ----------
  bool get esClon => eventoBase != null;
  List<IglesiaModel> get iglesias => _iglesias;
  bool get cargandoIglesias => _cargandoIglesias;
  String? get idIglesia => _idIglesia;
  IglesiaModel? get iglesiaSeleccionada {
    for (final i in _iglesias) {
      if (i.idIglesia == _idIglesia) return i;
    }
    return null;
  }

  TipoActividad get tipoActividad => _tipoActividad;

  /// Tipos que ofrece el formulario en esta app (ej. Misa y Reunión en la
  /// App 1). Al clonar se conserva el tipo original aunque no esté en la
  /// lista, para no cambiar el dato.
  List<TipoActividad> get tiposActividad {
    final base = terminologia.tiposActividad;
    final t = eventoBase?.tipoActividad;
    if (t == null || base.contains(t)) return base;
    return [
      for (final v in TipoActividad.values)
        if (base.contains(v) || v == t) v,
    ];
  }

  String? get categoria => _categoria;
  DateTime get fecha => _fecha;
  List<HoraDelDia> get turnos => _turnos.toList()..sort();
  Duration? get duracion => _duracion;
  bool get esVirtual => _esVirtual;

  /// Una iglesia virtual no tiene pin: sus eventos siempre son virtuales.
  bool get virtualBloqueado =>
      iglesiaSeleccionada?.tipo == TipoUbicacion.virtual;
  FrecuenciaRecurrencia get frecuencia => _frecuencia;
  bool get seRepite => _frecuencia != FrecuenciaRecurrencia.ninguna;
  bool get terminaPorFecha => _terminaPorFecha;
  DateTime get fechaFin => _fechaFin;
  int get repeticiones => _repeticiones;
  bool get guardando => _guardando;
  String? get error => _error;

  /// Categorías del formulario (incluye la del evento clonado si no está en la lista).
  List<String> get categorias {
    final base = [...AppConstants.categoriasEventos];
    final c = eventoBase?.categoria;
    if (c != null && c.isNotEmpty && !base.contains(c)) base.add(c);
    return base;
  }

  DateTime get hoy {
    final a = _reloj();
    return DateTime(a.year, a.month, a.day);
  }

  /// Última fecha permitida (ventana de 16 meses).
  DateTime get fechaMaxima =>
      DateTime(hoy.year, hoy.month + AppConstants.historialMaxMeses, hoy.day);

  // ---------- Cambios ----------
  void elegirIglesia(String? id) {
    _idIglesia = id;
    _sincronizarVirtualSegunIglesia();
    notifyListeners();
  }

  void cambiarTipoActividad(TipoActividad t) {
    _tipoActividad = t;
    notifyListeners();
  }

  void cambiarCategoria(String? c) {
    _categoria = c;
    notifyListeners();
  }

  void cambiarFecha(DateTime f) {
    _fecha = DateTime(f.year, f.month, f.day);
    if (_fechaFin.isBefore(_fecha)) {
      _fechaFin = _fecha.add(const Duration(days: 28));
    }
    notifyListeners();
  }

  void alternarTurno(HoraDelDia h) {
    if (!_turnos.remove(h)) _turnos.add(h);
    notifyListeners();
  }

  void agregarTurno(HoraDelDia h) {
    _turnos.add(h);
    notifyListeners();
  }

  void quitarTurno(HoraDelDia h) {
    _turnos.remove(h);
    notifyListeners();
  }

  void cambiarDuracion(Duration? d) {
    _duracion = d;
    notifyListeners();
  }

  void cambiarVirtual(bool v) {
    if (virtualBloqueado) return;
    _esVirtual = v;
    notifyListeners();
  }

  void cambiarFrecuencia(FrecuenciaRecurrencia f) {
    _frecuencia = f;
    notifyListeners();
  }

  void cambiarTerminaPorFecha(bool porFecha) {
    _terminaPorFecha = porFecha;
    notifyListeners();
  }

  void cambiarFechaFin(DateTime f) {
    _fechaFin = DateTime(f.year, f.month, f.day);
    notifyListeners();
  }

  void cambiarRepeticiones(int n) {
    _repeticiones = n.clamp(1, AppConstants.maxRepeticionesFormulario);
    notifyListeners();
  }

  // ---------- Recurrencia ----------
  ReglaRecurrencia get regla => ReglaRecurrencia(
        fechaInicio: _fecha,
        turnos: turnos,
        frecuencia: _frecuencia,
        fechaFin: seRepite && _terminaPorFecha ? _fechaFin : null,
        repeticiones: seRepite && !_terminaPorFecha ? _repeticiones : null,
      );

  /// Fechas que se crearían, sin las que ya pasaron. null si la regla es inválida.
  ResultadoRecurrencia? get vistaPrevia {
    if (_turnos.isEmpty) return null;
    try {
      final r = _generador.generar(regla);
      final ahora = _reloj();
      return ResultadoRecurrencia(
        ocurrencias:
            r.ocurrencias.where((o) => o.inicio.isAfter(ahora)).toList(),
        recortadoPorMaximo: r.recortadoPorMaximo,
        recortadoPorVentana: r.recortadoPorVentana,
      );
    } on ArgumentError {
      return null;
    }
  }

  /// Cuántos horarios se descartaron por estar en el pasado (ej. hoy a las 7:00).
  int get horariosPasados {
    if (_turnos.isEmpty) return 0;
    try {
      final r = _generador.generar(regla);
      final ahora = _reloj();
      return r.ocurrencias.where((o) => !o.inicio.isAfter(ahora)).length;
    } on ArgumentError {
      return 0;
    }
  }

  // ---------- Guardar ----------
  /// Valida lo que no cubren los campos de texto. Devuelve el error o null.
  String? validarSelecciones() {
    if (_idIglesia == null) return 'Elige la iglesia del evento.';
    if (_categoria == null) return 'Elige una categoría.';
    if (_turnos.isEmpty) return 'Elige al menos una hora.';
    if (_fecha.isBefore(hoy)) return 'La fecha no puede estar en el pasado.';
    if (seRepite && _terminaPorFecha && _fechaFin.isBefore(_fecha)) {
      return 'La fecha final debe ser igual o posterior a la fecha de inicio.';
    }
    final vista = vistaPrevia;
    if (vista == null || vista.ocurrencias.isEmpty) {
      return 'Todas las horas elegidas ya pasaron. Elige otra fecha u hora.';
    }
    return null;
  }

  /// Crea los eventos. Devuelve cuántos se crearon, o null si hubo error.
  Future<int?> guardar({
    required String titulo,
    String? descripcion,
    String? linkVirtual,
    String? imagenUrl,
  }) async {
    final errorSeleccion = validarSelecciones();
    if (errorSeleccion != null) {
      _error = errorSeleccion;
      notifyListeners();
      return null;
    }
    final List<OcurrenciaEvento> ocurrencias = vistaPrevia!.ocurrencias;

    _guardando = true;
    _error = null;
    notifyListeners();
    try {
      final ids = await _eventos.crearEventos(
        DatosNuevoEvento(
          tipoActividad: _tipoActividad,
          titulo: titulo,
          categoria: _categoria!,
          descripcion: descripcion,
          idIglesia: _idIglesia,
          esVirtual: _esVirtual,
          linkVirtual: _esVirtual ? linkVirtual : null,
          imagenUrl: imagenUrl,
          duracion: _duracion,
        ),
        ocurrencias,
      );
      return ids.length;
    } on ArgumentError catch (e) {
      _error = '${e.message}';
      return null;
    } on SesionRequeridaException catch (e) {
      _error = e.toString();
      return null;
    } catch (e) {
      _error = 'No se pudo guardar el evento. Inténtalo de nuevo.\n($e)';
      return null;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  // ---------- Internos ----------
  void _prellenar() {
    _fecha = hoy.add(const Duration(days: 1));
    _fechaFin = _fecha.add(const Duration(days: 28));
    final base = eventoBase;
    if (base == null) {
      _turnos.add(const HoraDelDia(19, 0));
      return;
    }
    _tipoActividad = base.tipoActividad;
    _categoria = base.categoria.isEmpty ? null : base.categoria;
    _esVirtual = base.esVirtual;
    _duracion = base.fechaHoraFin?.difference(base.fechaHoraInicio);
    if (_duracion != null && !duraciones.contains(_duracion)) {
      _duracion = const Duration(hours: 1);
    }
    _turnos.add(
        HoraDelDia(base.fechaHoraInicio.hour, base.fechaHoraInicio.minute));

    // Misma fecha si todavía no pasa; si no, el mismo día de la semana más próximo.
    final diaBase = DateTime(base.fechaHoraInicio.year,
        base.fechaHoraInicio.month, base.fechaHoraInicio.day);
    if (diaBase.isAfter(hoy)) {
      _fecha = diaBase;
    } else {
      var dif = (diaBase.weekday - hoy.weekday) % 7;
      if (dif == 0) dif = 7;
      _fecha = hoy.add(Duration(days: dif));
    }
    _fechaFin = _fecha.add(const Duration(days: 28));

    tituloInicial = base.titulo;
    descripcionInicial = base.descripcion ?? '';
    linkInicial = base.linkVirtual ?? '';
    imagenInicial = base.imagenUrl ?? '';
  }

  void _sincronizarVirtualSegunIglesia() {
    if (virtualBloqueado) _esVirtual = true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
