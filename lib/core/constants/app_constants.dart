import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract final class AppConstants {
  // ---------- Ubicación por defecto: Lima, Perú ----------
  static const double limaLatitud = -12.046374;
  static const double limaLongitud = -77.042793;
  static const LatLng centroLima = LatLng(limaLatitud, limaLongitud);
  static const double zoomInicialMapa = 11.5;

  static const String paisPorDefecto = 'Perú';
  static const String localidadPorDefecto = 'Lima';

  // ---------- Ventanas de tiempo ----------
  /// RF-5.2: el mapa y la lista muestran eventos de los próximos 30 días.
  static const int ventanaEventosDias = 30;

  /// RF-5.4: el historial filtra como máximo 16 meses hacia atrás.
  static const int historialMaxMeses = 16;

  // ---------- Límites de consulta (capa gratuita Spark, RNF-3) ----------
  static const int maxEventosPorConsulta = 200;
  static const int maxHistorialPorConsulta = 100;

  // ---------- Recurrencia sin Cloud Functions (RF-4.4) ----------
  /// Máximo de eventos que se generan de una sola vez al repetir un evento.
  static const int maxOcurrenciasRecurrencia = 60;

  /// Máximo de repeticiones que se puede escribir en el formulario.
  static const int maxRepeticionesFormulario = 60;

  // ---------- Categorías de eventos (RF-5.5) ----------
  static const List<String> categoriasEventos = [
    'General',
    'Jóvenes',
    'Niños',
    'Ayuno',
    'Oración',
    'Matrimonios',
    'Estudio Bíblico',
    'Alabanza',
    'Retiro',
    'Servicio Social',
  ];

  // ---------- Gamificación (App 6, Fase 2): solo prevista ----------
  static const double radioCheckinMetros = 100;
  static const int horasEntreCheckinsPorIglesia = 12;
}
