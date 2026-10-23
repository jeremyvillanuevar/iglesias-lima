import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_flavor.dart';

import '../../data/repositories/reglas_reclamo.dart';
import '../shared/layout/margenes_sistema.dart';
import '../shared/widgets/cargando.dart';
import '../shared/widgets/chip_sin_administrador.dart';
import 'reclamar_iglesia_view_model.dart';

/// "Reclamar / gestionar esta iglesia": el usuario pide administrar una
/// iglesia sin administrador. Queda Pendiente hasta que el Admin General la
/// apruebe en Moderación.
class ReclamarIglesiaScreen extends StatefulWidget {
  const ReclamarIglesiaScreen({super.key});

  @override
  State<ReclamarIglesiaScreen> createState() => _ReclamarIglesiaScreenState();
}

class _ReclamarIglesiaScreenState extends State<ReclamarIglesiaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargo = TextEditingController();
  final _mensaje = TextEditingController();

  @override
  void dispose() {
    _cargo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<ReclamarIglesiaViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.enviar(cargo: _cargo.text, mensaje: _mensaje.text);
    if (ok && mounted) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Solicitud enviada. Te avisaremos al revisarla.')));
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final terminologia = context.read<AppFlavor>().terminologia;
    final vm = context.watch<ReclamarIglesiaViewModel>();
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reclamar / gestionar iglesia')),
      body: SafeArea(
        bottom: false,
        child: vm.cargando
            ? const Cargando(mensaje: 'Revisando tu solicitud…')
            : Form(
                key: _formKey,
                child: ListView(
                  padding: MargenesSistema.formulario(context),
                  children: [
                    Text(vm.iglesia.nombre,
                        style: tema.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ChipSinAdministrador(
                          estado: vm.iglesia.estadoAdministracion),
                    ),
                    if (vm.iglesia.direccionTexto != null) ...[
                      const SizedBox(height: 6),
                      Text(vm.iglesia.direccionTexto!,
                          style: tema.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 16),
                    Card(
                      color: tema.colorScheme.surfaceContainerHighest,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Si eres responsable de esta iglesia puedes pedir '
                          'administrarla. El Administrador General revisará '
                          'tu solicitud; mientras tanto la iglesia sigue sin '
                          'administrador.',
                        ),
                      ),
                    ),
                    if (vm.textoEstado != null) ...[
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline),
                        title: Text(vm.textoEstado!),
                      ),
                    ],
                    if (vm.puedeEnviar) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cargo,
                        maxLength: ReglasReclamo.maxCargo,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Tu cargo en la iglesia *',
                          hintText: terminologia.ejemploCargo,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Indica tu cargo en la iglesia.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mensaje,
                        maxLength: ReglasReclamo.maxMensaje,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Mensaje para el administrador (opcional)',
                          hintText: 'Cómo podemos verificar que eres '
                              'responsable (${terminologia.ejemploContacto}, etc.)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (vm.error != null) ...[
                      const SizedBox(height: 8),
                      Text(vm.error!,
                          style: TextStyle(color: tema.colorScheme.error)),
                    ],
                    if (vm.puedeEnviar) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: vm.enviando ? null : _enviar,
                        icon: vm.enviando
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: const Text('Enviar solicitud'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
