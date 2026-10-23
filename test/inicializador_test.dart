import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/config/google_sign_in_config.dart';
import 'package:iglesias_app/core/config/maps_config.dart';
import 'package:iglesias_app/core/di/inicializador_app.dart';
import 'package:iglesias_app/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('App 1 (Católica) tiene Firebase real: el Modo Demo se apaga solo', () {
    expect(InicializadorApp.tienePlaceholders(AppFlavor.catolica), isFalse);
    final android = DefaultFirebaseOptions.androidDe(AppFlavor.catolica);
    expect(android.projectId, 'iglesias-lima');
    expect(android.appId, '1:229289277006:android:c263b9e76af88e5227751f');
    final web = DefaultFirebaseOptions.webDe(AppFlavor.catolica);
    expect(web.appId, '1:229289277006:web:a0e127c754b453d927751f');
    expect(web.authDomain, 'iglesias-lima.firebaseapp.com');
    expect(GoogleSignInConfig.serverClientIdOrNull, isNotNull);
  });

  test('App 2 (Evangélica) tiene Firebase real en Android: sin Modo Demo', () {
    expect(InicializadorApp.tienePlaceholders(AppFlavor.evangelica), isFalse);
    final android = DefaultFirebaseOptions.androidDe(AppFlavor.evangelica);
    expect(android.appId, '1:229289277006:android:21d73df3ca75b30727751f');
    expect(android.appId,
        isNot(DefaultFirebaseOptions.androidDe(AppFlavor.catolica).appId));
    expect(AppFlavor.entregadas, contains(AppFlavor.evangelica));
  });

  test('las apps sin App ID real siguen en Modo Demo', () async {
    const conFirebase = {AppFlavor.catolica, AppFlavor.evangelica};
    for (final f in AppFlavor.values.where((f) => !conFirebase.contains(f))) {
      expect(InicializadorApp.tienePlaceholders(f), isTrue, reason: f.id);
    }
    final deps = await InicializadorApp.inicializar(AppFlavor.jehova);
    expect(deps.configuracion.modoDemo, isTrue);
    expect(deps.configuracion.flavor, AppFlavor.jehova);
    expect(deps.configuracion.motivoModoDemo, contains('PEGA_AQUI'));
  });

  test('App 1 trae clave de Google Maps y cae a OpenStreetMap si falla', () {
    expect(MapsConfig.claveConfigurada, isTrue);
    // flutter_test_config.dart activa el respaldo (no hay mapa nativo).
    expect(MapsConfig.respaldoOsm.value, isTrue);
    expect(MapsConfig.usarGoogleMaps, isFalse);
  });
}
