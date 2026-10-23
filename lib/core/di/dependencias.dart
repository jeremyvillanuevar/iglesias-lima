import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/demo/demo_auth_repository.dart';
import '../../data/demo/demo_data_store.dart';
import '../../data/demo/demo_evento_repository.dart';
import '../../data/demo/demo_iglesia_repository.dart';
import '../../data/demo/demo_importacion_iglesias_repository.dart';
import '../../data/demo/demo_ministerio_repository.dart';
import '../../data/demo/demo_reclamo_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/evento_repository.dart';
import '../../data/repositories/firebase/firebase_auth_repository.dart';
import '../../data/repositories/firebase/firebase_evento_repository.dart';
import '../../data/repositories/firebase/firebase_iglesia_repository.dart';
import '../../data/repositories/firebase/firebase_importacion_iglesias_repository.dart';
import '../../data/repositories/firebase/firebase_ministerio_repository.dart';
import '../../data/repositories/firebase/firebase_reclamo_repository.dart';
import '../../data/repositories/iglesia_repository.dart';
import '../../data/repositories/importacion_iglesias_repository.dart';
import '../../data/repositories/ministerio_repository.dart';
import '../../data/repositories/reclamo_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/evento_service.dart';
import '../../data/services/iglesia_service.dart';
import '../../data/services/ministerio_service.dart';
import '../../data/services/solicitud_reclamo_service.dart';
import '../../data/services/user_service.dart';
import '../../data/repositories/filtrado/evento_repository_por_denominacion.dart';
import '../../data/repositories/filtrado/iglesia_repository_por_denominacion.dart';
import '../../data/repositories/filtrado/ministerio_repository_por_denominacion.dart';
import '../../data/repositories/filtrado/reclamo_repository_por_denominacion.dart';
import '../../data/repositories/filtrado/resolutor_denominacion.dart';
import '../config/app_flavor.dart';
import '../config/configuracion_app.dart';
import '../config/google_sign_in_config.dart';

/// Repositorios elegidos UNA sola vez al arrancar (Firebase o Demo).
/// Los ViewModels solo conocen las interfaces abstractas.
///
/// En las Apps de una sola denominación (Apps 1 a 4) los repositorios se
/// envuelven con los decoradores "PorDenominacion", que filtran iglesias,
/// ministerios y eventos del lado del cliente.
class Dependencias {
  const Dependencias._({
    required this.configuracion,
    required this.auth,
    required this.iglesias,
    required this.eventos,
    required this.ministerios,
    required this.reclamos,
    required this.importacion,
  });

  final ConfiguracionApp configuracion;
  final AuthRepository auth;
  final IglesiaRepository iglesias;
  final EventoRepository eventos;
  final MinisterioRepository ministerios;
  final ReclamoRepository reclamos;
  final ImportacionIglesiasRepository importacion;

  /// Implementación real. Requiere que Firebase.initializeApp ya haya funcionado.
  factory Dependencias.firebase([AppFlavor flavor = AppFlavor.porDefecto]) {
    final authService = AuthService(
      googleSignIn: GoogleSignIn(
        scopes: const ['email'],
        // En web el login con Google usa el popup de Firebase (no este objeto).
        clientId: kIsWeb ? GoogleSignInConfig.serverClientIdOrNull : null,
        serverClientId: kIsWeb ? null : GoogleSignInConfig.serverClientIdOrNull,
      ),
    );
    final userService = UserService();
    final iglesiaService = IglesiaService();
    final ministerioService = MinisterioService();
    final eventoService = EventoService();

    final auth = FirebaseAuthRepository(
      authService: authService,
      userService: userService,
    );
    return Dependencias._conFlavor(
      flavor: flavor,
      configuracion: ConfiguracionApp(modoDemo: false, flavor: flavor),
      auth: auth,
      iglesias: FirebaseIglesiaRepository(
        iglesiaService: iglesiaService,
        authRepository: auth,
      ),
      eventos: FirebaseEventoRepository(
        eventoService: eventoService,
        iglesiaService: iglesiaService,
        ministerioService: ministerioService,
        authRepository: auth,
      ),
      ministerios: FirebaseMinisterioRepository(
        ministerioService: ministerioService,
        iglesiaService: iglesiaService,
        authRepository: auth,
      ),
      reclamos: FirebaseReclamoRepository(
        solicitudService: SolicitudReclamoService(),
        iglesiaService: iglesiaService,
        userService: userService,
        authRepository: auth,
      ),
      importacion: FirebaseImportacionIglesiasRepository(
        iglesiaService: iglesiaService,
        authRepository: auth,
      ),
    );
  }

  /// Modo Demo: todo en memoria con datos de ejemplo.
  factory Dependencias.demo({
    AppFlavor flavor = AppFlavor.porDefecto,
    String? motivo,
    DemoDataStore? store,
  }) {
    final datos = store ?? DemoDataStore();
    final auth = DemoAuthRepository(datos);
    return Dependencias._conFlavor(
      flavor: flavor,
      configuracion: ConfiguracionApp(
        modoDemo: true,
        motivoModoDemo: motivo,
        flavor: flavor,
      ),
      auth: auth,
      iglesias: DemoIglesiaRepository(datos, auth),
      eventos: DemoEventoRepository(datos, auth),
      ministerios: DemoMinisterioRepository(datos, auth),
      reclamos: DemoReclamoRepository(datos, auth),
      importacion: DemoImportacionIglesiasRepository(datos, auth),
    );
  }

  /// Aplica el filtro por denominación si la app es de una sola denominación.
  factory Dependencias._conFlavor({
    required AppFlavor flavor,
    required ConfiguracionApp configuracion,
    required AuthRepository auth,
    required IglesiaRepository iglesias,
    required EventoRepository eventos,
    required MinisterioRepository ministerios,
    required ReclamoRepository reclamos,
    required ImportacionIglesiasRepository importacion,
  }) {
    final denominacion = flavor.denominacionFija;
    if (denominacion == null) {
      return Dependencias._(
        configuracion: configuracion,
        auth: auth,
        iglesias: iglesias,
        eventos: eventos,
        ministerios: ministerios,
        reclamos: reclamos,
        importacion: importacion,
      );
    }
    final resolutor =
        ResolutorDenominacion(iglesias: iglesias, ministerios: ministerios);
    return Dependencias._(
      configuracion: configuracion,
      auth: auth,
      iglesias: IglesiaRepositoryPorDenominacion(
        base: iglesias,
        denominacion: denominacion,
        resolutor: resolutor,
      ),
      eventos: EventoRepositoryPorDenominacion(
        base: eventos,
        denominacion: denominacion,
        resolutor: resolutor,
      ),
      ministerios: MinisterioRepositoryPorDenominacion(
        base: ministerios,
        denominacion: denominacion,
        resolutor: resolutor,
      ),
      reclamos: ReclamoRepositoryPorDenominacion(
        base: reclamos,
        denominacion: denominacion,
      ),
      // La importación ya va por denominación (FuenteImportacionOsm).
      importacion: importacion,
    );
  }
}
