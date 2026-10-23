import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';
import '../shared/layout/margenes_sistema.dart';
import '../shared/map/selector_ubicacion_mapa.dart';
import '../shared/widgets/campo_denominacion.dart';
import '../shared/widgets/chip_pendiente.dart';
import 'crear_ministerio_view_model.dart';

/// Formulario "Nuevo ministerio" (RF-3.1 a RF-3.3). Al guardar queda
/// Pendiente y el creador es su "Administrador de Ministerio".
/// Devuelve el id creado al hacer pop.
class CrearMinisterioScreen extends StatefulWidget {
  const CrearMinisterioScreen({super.key});

  @override
  State<CrearMinisterioScreen> createState() => _CrearMinisterioScreenState();
}

class _CrearMinisterioScreenState extends State<CrearMinisterioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _link = TextEditingController();
  final _pais = TextEditingController(text: AppConstants.paisPorDefecto);
  final _localidad =
      TextEditingController(text: AppConstants.localidadPorDefecto);

  @override
  void dispose() {
    for (final c in [_nombre, _link, _pais, _localidad]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final vm = context.read<CrearMinisterioViewModel>();
    final formOk = _formKey.currentState!.validate();
    final seleccionOk = vm.validarSelecciones();
    if (!formOk || !seleccionOk) return;

    final id = await vm.guardar(
      nombre: _nombre.text,
      linkVirtual: _link.text,
      pais: _pais.text,
      localidad: _localidad.text,
    );
    if (id != null && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrearMinisterioViewModel>();
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo ministerio')),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            // Margen inferior = barra del sistema: el botón Guardar no queda tapado.
            padding: MargenesSistema.formulario(context),
            children: [
              _Aviso(tituloLider: vm.terminologia.tituloLider),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nombre del ministerio *',
                  hintText: vm.terminologia.ejemploMinisterio,
                  prefixIcon: const Icon(Icons.groups_outlined),
                ),
                validator: (v) => Validators.requerido(v, campo: 'El nombre'),
              ),
              const SizedBox(height: 16),
              Text('¿Dónde funciona? *', style: tema.textTheme.titleSmall),
              const SizedBox(height: 6),
              SegmentedButton<TipoUbicacionMinisterio>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: TipoUbicacionMinisterio.iglesia,
                    icon: Icon(Icons.church_outlined),
                    label: Text('En una iglesia'),
                  ),
                  ButtonSegment(
                    value: TipoUbicacionMinisterio.fisica,
                    icon: Icon(Icons.place_outlined),
                    label: Text('Sede propia'),
                  ),
                  ButtonSegment(
                    value: TipoUbicacionMinisterio.virtual,
                    icon: Icon(Icons.language),
                    label: Text('Virtual'),
                  ),
                ],
                selected: {vm.tipo},
                onSelectionChanged: (s) => vm.cambiarTipo(s.first),
              ),
              const SizedBox(height: 4),
              Text(
                switch (vm.tipo) {
                  TipoUbicacionMinisterio.iglesia =>
                    'Vinculado a una iglesia matriz (RF-3.2).',
                  TipoUbicacionMinisterio.fisica =>
                    'Independiente, con un lugar físico propio (RF-3.3).',
                  TipoUbicacionMinisterio.virtual =>
                    'Independiente y estrictamente virtual (RF-3.3).',
                },
                style: tema.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (vm.vinculadoAIglesia) _selectorIglesia(vm),
              if (vm.esFisico) ...[
                SelectorUbicacionMapa(
                  seleccion: vm.ubicacion,
                  onCambio: vm.elegirUbicacion,
                  errorTexto: vm.errorUbicacion,
                  instruccion: 'Toca el mapa para marcar dónde se reúne',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pais,
                        decoration: const InputDecoration(labelText: 'País *'),
                        validator: (v) =>
                            Validators.requerido(v, campo: 'El país'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _localidad,
                        decoration: const InputDecoration(
                            labelText: 'Ciudad / localidad *'),
                        validator: (v) =>
                            Validators.requerido(v, campo: 'La localidad'),
                      ),
                    ),
                  ],
                ),
              ],
              if (vm.esVirtual)
                TextFormField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Enlace web (transmisión, grupo o red social) *',
                    hintText: 'https://…',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: Validators.url,
                ),
              const SizedBox(height: 16),
              CampoDenominacion(
                valor: vm.denominacion,
                bloqueada: vm.denominacionBloqueada,
                onCambio: vm.cambiarDenominacion,
                ayuda: vm.ayudaDenominacion,
              ),
              const SizedBox(height: 20),
              if (vm.error != null) ...[
                Text(vm.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tema.colorScheme.error)),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: vm.guardando ? null : _guardar,
                icon: vm.guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar ministerio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectorIglesia(CrearMinisterioViewModel vm) {
    if (vm.cargandoIglesias) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }
    if (vm.iglesias.isEmpty) {
      return Text(
        'No hay iglesias disponibles. Registra primero la iglesia o crea el '
        'ministerio como independiente.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: vm.idIglesia,
      decoration: InputDecoration(
        labelText: 'Iglesia matriz *',
        prefixIcon: const Icon(Icons.church_outlined),
        errorText: vm.errorIglesia,
      ),
      items: [
        for (final i in vm.iglesias)
          DropdownMenuItem(
            value: i.idIglesia,
            child: Row(children: [
              CircleAvatar(
                  radius: 6,
                  backgroundColor: AppTheme.colorDenominacion(i.denominacion)),
              const SizedBox(width: 8),
              Expanded(child: Text(i.nombre, overflow: TextOverflow.ellipsis)),
              if (i.estadoAprobacion == EstadoAprobacion.pendiente)
                const ChipPendiente(),
            ]),
          ),
      ],
      onChanged: vm.elegirIglesia,
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.tituloLider});

  /// Ej. 'Padre' en la App 1 (según la denominación de la app).
  final String tituloLider;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Serás el "Administrador de Ministerio" (coordinador). El '
                'ministerio se guardará como "Pendiente" hasta que lo apruebe '
                'el $tituloLider de la iglesia matriz o el Administrador General.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
