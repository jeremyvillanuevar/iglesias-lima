import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import 'auth_view_model.dart';

/// Registro con nombre, correo y contraseña (RF-1.1).
/// Devuelve `true` al hacer pop si la cuenta se creó.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _clave2 = TextEditingController();
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
    _nombre.dispose();
    _correo.dispose();
    _clave.dispose();
    _clave2.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthViewModel>().registrar(
          nombre: _nombre.text,
          email: _correo.text,
          password: _clave.text,
        );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.nombre,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
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
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Contraseña (mínimo 6 caracteres)',
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clave2,
                      obscureText: !_verClave,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _registrar(),
                      decoration: const InputDecoration(
                        labelText: 'Repite la contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator:
                          Validators.confirmarContrasena(() => _clave.text),
                    ),
                    const SizedBox(height: 16),
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
                      onPressed: vm.cargando ? null : _registrar,
                      child: vm.cargando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Ya tengo cuenta'),
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
