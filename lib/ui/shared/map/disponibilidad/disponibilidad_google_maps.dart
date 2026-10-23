/// ¿Está listo Google Maps en esta plataforma?
///
/// - Android: siempre "listo" (el SDK nativo lee la clave del manifest).
/// - Web: espera a que web/index.html termine de cargar Maps JavaScript API y
///   avisa si falla (script bloqueado, clave rechazada, sin facturación).
library;

export 'disponibilidad_google_maps_io.dart'
    if (dart.library.js_interop) 'disponibilidad_google_maps_web.dart';
