import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/evento_repository.dart';
import '../../data/repositories/iglesia_repository.dart';
import '../../data/models/iglesia_model.dart';
import '../../data/repositories/ministerio_repository.dart';
import '../../data/repositories/reclamo_repository.dart';
import '../../ui/admin/moderacion_screen.dart';
import '../../ui/admin/moderacion_view_model.dart';
import '../../ui/auth/auth_view_model.dart';
import '../../ui/auth/login_screen.dart';
import '../../ui/auth/register_screen.dart';
import '../../ui/evento_form/crear_evento_screen.dart';
import '../../ui/evento_form/crear_evento_view_model.dart';
import '../../ui/home_map/home_map_screen.dart';
import '../../ui/home_map/home_map_view_model.dart';
import '../../ui/iglesia_form/crear_iglesia_screen.dart';
import '../../ui/iglesia_form/crear_iglesia_view_model.dart';
import '../../ui/ministerio_form/crear_ministerio_screen.dart';
import '../../ui/ministerio_form/crear_ministerio_view_model.dart';
import '../../ui/reclamo/reclamar_iglesia_screen.dart';
import '../../ui/reclamo/reclamar_iglesia_view_model.dart';
import '../config/app_flavor.dart';
import 'crear_evento_args.dart';

/// Rutas de la app. Cada pantalla recibe aquí su ViewModel (MVVM + Provider).
abstract final class AppRouter {
  static const String inicio = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String crearIglesia = '/crear-iglesia';
  static const String crearEvento = '/crear-evento';
  static const String crearMinisterio = '/crear-ministerio';
  static const String moderacion = '/moderacion';
  static const String reclamarIglesia = '/reclamar-iglesia';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case inicio:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (c) => HomeMapViewModel(
              iglesiaRepository: c.read<IglesiaRepository>(),
              eventoRepository: c.read<EventoRepository>(),
              flavor: c.read<AppFlavor>(),
            ),
            child: const HomeMapScreen(),
          ),
        );
      case login:
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case registro:
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );
      case crearIglesia:
        return MaterialPageRoute<String>(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (c) => CrearIglesiaViewModel(
              iglesiaRepository: c.read<IglesiaRepository>(),
              flavor: c.read<AppFlavor>(),
            ),
            child: const CrearIglesiaScreen(),
          ),
        );
      case crearEvento:
        final args = settings.arguments is CrearEventoArgs
            ? settings.arguments! as CrearEventoArgs
            : const CrearEventoArgs();
        return MaterialPageRoute<int>(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (c) => CrearEventoViewModel(
              eventoRepository: c.read<EventoRepository>(),
              iglesiaRepository: c.read<IglesiaRepository>(),
              terminologia: c.read<AppFlavor>().terminologia,
              idIglesiaInicial: args.idIglesia,
              eventoBase: args.eventoBase,
            ),
            child: const CrearEventoScreen(),
          ),
        );
      case crearMinisterio:
        final idIglesia =
            settings.arguments is String ? settings.arguments! as String : null;
        return MaterialPageRoute<String>(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (c) => CrearMinisterioViewModel(
              ministerioRepository: c.read<MinisterioRepository>(),
              iglesiaRepository: c.read<IglesiaRepository>(),
              flavor: c.read<AppFlavor>(),
              idIglesiaInicial: idIglesia,
            ),
            child: const CrearMinisterioScreen(),
          ),
        );
      case moderacion:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (c) => ModeracionViewModel(
              authRepository: c.read<AuthRepository>(),
              iglesiaRepository: c.read<IglesiaRepository>(),
              ministerioRepository: c.read<MinisterioRepository>(),
              eventoRepository: c.read<EventoRepository>(),
              reclamoRepository: c.read<ReclamoRepository>(),
              terminologia: c.read<AppFlavor>().terminologia,
            ),
            child: const ModeracionScreen(),
          ),
        );
      case reclamarIglesia:
        final iglesia = settings.arguments;
        if (iglesia is! IglesiaModel) {
          return _noEncontrada(settings);
        }
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (c) => ReclamarIglesiaViewModel(
              reclamoRepository: c.read<ReclamoRepository>(),
              iglesia: iglesia,
            ),
            child: const ReclamarIglesiaScreen(),
          ),
        );
      default:
        return _noEncontrada(settings);
    }
  }

  static Route<dynamic> _noEncontrada(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Página no encontrada')),
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil(inicio, (_) => false),
            child: const Text('Volver al mapa'),
          ),
        ),
      ),
    );
  }

  /// Devuelve true si hay sesión; si no, abre el login y espera el resultado.
  static Future<bool> requerirSesion(BuildContext context) async {
    if (context.read<AuthViewModel>().haySesion) return true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
          content: Text(
              'Inicia sesión para crear iglesias, ministerios o eventos.')),
    );
    final ok = await Navigator.of(context).pushNamed<bool>(login);
    return ok == true;
  }
}
