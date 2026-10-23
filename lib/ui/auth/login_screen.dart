import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_flavor.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/validators.dart';
import '../shared/widgets/banner_modo_demo.dart';
import 'auth_view_model.dart';
import 'widgets/boton_google.dart';

/// Inicio de sesión con correo/contraseña o Google (RF-1.1).
/// Devuelve `true` al hacer pop si se inició sesión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _verClave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().limpiarError();
    });
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrarConCorreo() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final ok = await vm.iniciarSesionConCorreo(_correo.text, _clave.text);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _entrarConGoogle() async {
    final ok = await context.read<AuthViewModel>().iniciarSesionConGoogle();
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _irARegistro() async {
    final ok = await Navigator.of(context).pushNamed<bool>(AppRouter.registro);
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _recuperarContrasena() async {
    final controlador = TextEditingController(text: _correo.text.trim());
    final claveForm = GlobalKey<FormState>();
    final vm = context.read<AuthViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final enviar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Form(
          key: claveForm,
          child: TextFormField(
            controller: controlador,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Tu correo'),
            validator: Validators.correo,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () {
              if (claveForm.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
    final correo = controlador.text;
    controlador.dispose();
    if (enviar != true) return;

    final ok = await vm.recuperarContrasena(correo);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? (vm.modoDemo
              ? 'Modo Demo: aquí se enviaría un correo para cambiar tu contraseña.'
              : 'Te enviamos un correo para restablecer tu contraseña.')
          : (vm.error ?? 'No se pudo enviar el correo.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final flavor = context.read<AppFlavor>();
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.church, size: 56, color: flavor.colorPrimario),
                    const SizedBox(height: 8),
                    Text(
                      flavor.nombreApp,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Inicia sesión para registrar iglesias, ministerios y eventos.',
                      textAlign: TextAlign.center,
                    ),
                    if (vm.modoDemo) ...[
                      const SizedBox(height: 12),
                      const Center(child: BannerModoDemo()),
                      const SizedBox(height: 6),
                      const Text(
                        'Puedes usar cualquier correo y una contraseña de 6 caracteres o más.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 20),
                    BotonGoogle(
                      onPressed: vm.cargando ? null : _entrarConGoogle,
                    ),
                    const SizedBox(height: 16),
                    const Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('o con tu correo'),
                      ),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.correo,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clave,
                      obscureText: !_verClave,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _entrarConCorreo(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                          icon: Icon(_verClave
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _verClave = !_verClave),
                        ),
                      ),
                      validator: Validators.contrasena,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: vm.cargando ? null : _recuperarContrasena,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    if (vm.error != null) ...[
                      Text(
                        vm.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton(
                      onPressed: vm.cargando ? null : _entrarConCorreo,
                      child: vm.cargando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: vm.cargando ? null : _irARegistro,
                      child: const Text('Crear una cuenta nueva'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                          'Seguir viendo el mapa sin iniciar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
