import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_router.dart';
import '../../../data/models/enums.dart';
import '../../auth/auth_view_model.dart';

/// Botón de la esquina: "Iniciar sesión" o el menú del usuario con
/// "Moderación" (Admin General / Pastor-Padre), el cambio de rol del Modo
/// Demo y "Cerrar sesión".
class BotonCuenta extends StatelessWidget {
  const BotonCuenta({super.key});

  static const String _salir = 'salir';
  static const String _moderacion = 'moderacion';
  static const String _prefijoRol = 'rol:';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (!auth.haySesion) {
      return IconButton(
        tooltip: 'Iniciar sesión',
        icon: const Icon(Icons.login),
        onPressed: () => Navigator.of(context).pushNamed<bool>(AppRouter.login),
      );
    }
    final nombre = auth.nombreVisible;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    final rolActual = auth.perfil?.rolGlobal;
    return PopupMenuButton<String>(
      tooltip: 'Mi cuenta',
      onSelected: (valor) => _alElegir(context, valor),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person),
            title: Text(nombre),
            subtitle: Text(
              '${auth.perfil?.email ?? ''}\n'
              '${rolActual == null ? '' : auth.etiquetaRol(rolActual)}',
            ),
            isThreeLine: true,
          ),
        ),
        if (auth.puedeModerar) ...[
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: _moderacion,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.admin_panel_settings_outlined),
              title: Text('Moderación'),
              subtitle: Text('Aprobar o rechazar lo Pendiente'),
            ),
          ),
        ],
        if (auth.puedeCambiarRolDemo) ...[
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            enabled: false,
            height: 32,
            child: Text('Modo Demo · actuar como:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          for (final rol in AuthViewModel.rolesDemo)
            PopupMenuItem<String>(
              value: '$_prefijoRol${rol.value}',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(rol == rolActual
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text(auth.etiquetaRol(rol)),
              ),
            ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _salir,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(inicial,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ),
    );
  }

  Future<void> _alElegir(BuildContext context, String valor) async {
    final auth = context.read<AuthViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    if (valor == _salir) {
      await auth.cerrarSesion();
      messenger.showSnackBar(const SnackBar(content: Text('Sesión cerrada.')));
    } else if (valor == _moderacion) {
      await Navigator.of(context).pushNamed<void>(AppRouter.moderacion);
    } else if (valor.startsWith(_prefijoRol)) {
      final rol = RolGlobal.fromValue(valor.substring(_prefijoRol.length));
      await auth.cambiarRolDemo(rol);
      messenger.showSnackBar(SnackBar(
          content:
              Text('Modo Demo: ahora actúas como ${auth.etiquetaRol(rol)}.')));
    }
  }
}
