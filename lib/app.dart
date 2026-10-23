import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/app_flavor.dart';
import 'core/config/configuracion_app.dart';
import 'core/config/terminologia.dart';
import 'core/di/dependencias.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/evento_repository.dart';
import 'data/repositories/iglesia_repository.dart';
import 'data/repositories/importacion_iglesias_repository.dart';
import 'data/repositories/ministerio_repository.dart';
import 'data/repositories/reclamo_repository.dart';
import 'ui/auth/auth_view_model.dart';

/// Raíz común de las Apps 1 a 5: inyecta el flavor y los repositorios
/// (Firebase o Demo) con Provider. Nombre y colores salen del [AppFlavor].
class IglesiasApp extends StatelessWidget {
  const IglesiasApp({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ConfiguracionApp>.value(value: dependencias.configuracion),
        Provider<AppFlavor>.value(value: dependencias.configuracion.flavor),
        Provider<Terminologia>.value(
            value: dependencias.configuracion.flavor.terminologia),
        Provider<AuthRepository>.value(value: dependencias.auth),
        Provider<IglesiaRepository>.value(value: dependencias.iglesias),
        Provider<EventoRepository>.value(value: dependencias.eventos),
        Provider<MinisterioRepository>.value(value: dependencias.ministerios),
        Provider<ReclamoRepository>.value(value: dependencias.reclamos),
        Provider<ImportacionIglesiasRepository>.value(
            value: dependencias.importacion),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(
            authRepository: dependencias.auth,
            modoDemo: dependencias.configuracion.modoDemo,
            terminologia: dependencias.configuracion.flavor.terminologia,
          ),
        ),
      ],
      child: MaterialApp(
        title: dependencias.configuracion.flavor.nombreApp,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro(dependencias.configuracion.flavor),
        locale: const Locale('es', 'PE'),
        supportedLocales: const [Locale('es', 'PE'), Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRouter.inicio,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
