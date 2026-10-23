import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import 'fuente_importacion_osm.dart';
import 'terminologia.dart';

/// Las apps del ecosistema que se compilan desde ESTE código (Apps 1 a 5).
///
/// Todas comparten un único proyecto de Firebase y las mismas cuentas de
/// usuario. Cada una es un "flavor" de Android (ver
/// android/app/build.gradle.kts) con su propio punto de entrada
/// (lib/main_<id>.dart).
///
/// La App 6 (Gamificación, el "Foursquare" de asistencia) es una app aparte:
/// solo está prevista en la arquitectura y NO se compila desde aquí.
enum AppFlavor {
  /// App 1
  catolica(
    id: 'catolica',
    numeroApp: 1,
    nombreApp: 'Iglesias Católicas Lima',
    applicationId: 'pe.iglesiaslima.catolica',
    colorPrimario: Color(0xFF6A1B9A),
    denominacionFija: Denominacion.catolica,
  ),

  /// App 2
  evangelica(
    id: 'evangelica',
    numeroApp: 2,
    nombreApp: 'Iglesias Evangélicas Lima',
    applicationId: 'pe.iglesiaslima.evangelica',
    colorPrimario: Color(0xFF0D47A1),
    denominacionFija: Denominacion.evangelica,
  ),

  /// App 3. (Gradle no admite flavors cuyo nombre empiece con "test",
  /// por eso el id es 'jehova'; el paquete sí es pe.iglesiaslima.testigos.)
  jehova(
    id: 'jehova',
    numeroApp: 3,
    nombreApp: 'Testigos de Jehová Lima',
    applicationId: 'pe.iglesiaslima.testigos',
    colorPrimario: Color(0xFF1B5E20),
    denominacionFija: Denominacion.testigosJehova,
  ),

  /// App 4
  ijsud(
    id: 'ijsud',
    numeroApp: 4,
    nombreApp: 'IJSUD Lima',
    applicationId: 'pe.iglesiaslima.ijsud',
    colorPrimario: Color(0xFF9A4A00),
    denominacionFija: Denominacion.santosUltimosDias,
  ),

  /// App 5: todas las denominaciones, con filtros.
  global(
    id: 'global',
    numeroApp: 5,
    nombreApp: 'Visión Global Cristiana',
    applicationId: 'pe.iglesiaslima.global',
    colorPrimario: Color(0xFF1F3A68),
    denominacionFija: null,
  );

  const AppFlavor({
    required this.id,
    required this.numeroApp,
    required this.nombreApp,
    required this.applicationId,
    required this.colorPrimario,
    required this.denominacionFija,
  });

  /// Nombre del flavor de Android (`--flavor <id>`).
  final String id;

  /// Número de la app dentro del ecosistema (1 a 5).
  final int numeroApp;

  /// Nombre visible (barra de título, login, banner del Modo Demo).
  final String nombreApp;

  /// Paquete de Android de esta app (debe registrarse en Firebase).
  final String applicationId;

  /// Color principal (semilla del tema).
  final Color colorPrimario;

  /// Única denominación que muestra la app; null = todas (App 5).
  final Denominacion? denominacionFija;

  /// Flavor por defecto cuando no se indica ninguno (web y `flutter run`
  /// sin `--flavor`). Hoy es la App 1, la que se entrega primero.
  static const AppFlavor porDefecto = AppFlavor.catolica;

  /// Apps que ya se entregan compiladas (las demás están declaradas y listas
  /// para activarse; ver ARQUITECTURA.md).
  static const List<AppFlavor> entregadas = [
    AppFlavor.catolica,
    AppFlavor.evangelica,
  ];

  /// Textos de pantalla propios de la denominación de esta app
  /// (ej. 'Padre' y 'Misa' en la App 1, 'Pastor' y 'Culto' en la App 2).
  Terminologia get terminologia => Terminologia.para(denominacionFija);

  /// Archivos de OpenStreetMap que el Admin General puede importar en esta
  /// app (vacío = la app aún no trae ninguno).
  List<FuenteImportacionOsm> get fuentesImportacionOsm =>
      FuenteImportacionOsm.para(denominacionesVisibles);

  /// true en las Apps 1 a 4.
  bool get esDenominacionUnica => denominacionFija != null;

  /// true si la app debe mostrar iglesias de la denominación [d].
  bool admite(Denominacion d) =>
      denominacionFija == null || denominacionFija == d;

  /// Denominaciones que se ven en esta app.
  List<Denominacion> get denominacionesVisibles =>
      denominacionFija == null ? Denominacion.values : [denominacionFija!];

  /// Busca el flavor por su id (ej. el valor de `appFlavor` de Flutter).
  /// Si es null, vacío o desconocido, devuelve [porDefecto].
  static AppFlavor desdeId(String? id) {
    for (final f in values) {
      if (f.id == id) return f;
    }
    return porDefecto;
  }
}
