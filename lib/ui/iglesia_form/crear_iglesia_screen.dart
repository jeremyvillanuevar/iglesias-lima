import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';
import 'crear_iglesia_view_model.dart';
import '../shared/layout/margenes_sistema.dart';
import '../shared/map/selector_ubicacion_mapa.dart';
import '../shared/widgets/campo_denominacion.dart';

/// Formulario "Nueva iglesia" (RF-2.1, RF-2.2). Al guardar queda Pendiente.
/// Devuelve el id creado al hacer pop.
class CrearIglesiaScreen extends StatefulWidget {
  const CrearIglesiaScreen({super.key});

  @override
  State<CrearIglesiaScreen> createState() => _CrearIglesiaScreenState();
}

class _CrearIglesiaScreenState extends State<CrearIglesiaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _link = TextEditingController();
  final _pais = TextEditingController(text: AppConstants.paisPorDefecto);
  final _localidad =
      TextEditingController(text: AppConstants.localidadPorDefecto);
  final _pastor = TextEditingController();
  final _aprobador = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _direccion,
      _link,
      _pais,
      _localidad,
      _pastor,
      _aprobador
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final vm = context.read<CrearIglesiaViewModel>();
    final formOk = _formKey.currentState!.validate();
    final ubicacionOk = vm.validarUbicacion();
    if (!formOk || !ubicacionOk) return;

    final id = await vm.guardar(
      nombre: _nombre.text,
      direccion: _direccion.text,
      linkVirtual: _link.text,
      pais: _pais.text,
      localidad: _localidad.text,
      pastor: _pastor.text,
      aprobador: _aprobador.text,
    );
    if (id != null && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrearIglesiaViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva iglesia')),
      // Sin SafeArea inferior: el margen se suma a la lista para que el
      // botón "Guardar" pueda quedar por encima de la barra de navegación.
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: MargenesSistema.formulario(context),
            children: [
              _Aviso(etiquetaInformada: vm.terminologia.etiquetaInformada),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la iglesia *',
                  prefixIcon: Icon(Icons.church_outlined),
                ),
                validator: (v) => Validators.requerido(v, campo: 'El nombre'),
              ),
              const SizedBox(height: 12),
              CampoDenominacion(
                valor: vm.denominacion,
                bloqueada: vm.denominacionBloqueada,
                onCambio: vm.cambiarDenominacion,
                ayuda: vm.denominacionBloqueada
                    ? 'En ${vm.flavor.nombreApp} solo se registran iglesias '
                        '${vm.denominacion.label}.'
                    : null,
              ),
              const SizedBox(height: 16),
              Text('Tipo de iglesia *',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              SegmentedButton<TipoUbicacion>(
                segments: const [
                  ButtonSegment(
                    value: TipoUbicacion.fisica,
                    icon: Icon(Icons.place_outlined),
                    label: Text('Física'),
                  ),
                  ButtonSegment(
                    value: TipoUbicacion.virtual,
                    icon: Icon(Icons.language),
                    label: Text('Virtual'),
                  ),
                ],
                selected: {vm.tipo},
                onSelectionChanged: (s) => vm.cambiarTipo(s.first),
              ),
              const SizedBox(height: 12),
              if (vm.esFisica) ...[
                SelectorUbicacionMapa(
                  seleccion: vm.ubicacion,
                  onCambio: vm.elegirUbicacion,
                  errorTexto: vm.errorUbicacion,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccion,
                  decoration: const InputDecoration(
                    labelText: 'Dirección (referencia)',
                    hintText: 'Ej. Av. Larco 123 – Miraflores',
                    prefixIcon: Icon(Icons.signpost_outlined),
                  ),
                ),
              ] else
                TextFormField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText:
                        'Enlace web (transmisión, página o red social) *',
                    hintText: 'https://…',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: Validators.url,
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
              const SizedBox(height: 4),
              const Text(
                'El mapa muestra las iglesias de la localidad "Lima".',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pastor,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: vm.terminologia.etiquetaCampoLider,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aprobador,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Aprobador',
                  helperText:
                      'Quién confirmará los datos (luego se vincula a su cuenta).',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: 20),
              if (vm.error != null) ...[
                Text(vm.error!,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
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
                label: const Text('Guardar iglesia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.etiquetaInformada});

  /// Ej. 'Informada por el laicado' (según la denominación de la app).
  final String etiquetaInformada;

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
                'La iglesia se guardará como "Pendiente" e "$etiquetaInformada". '
                'Solo tú y el aprobador la verán hasta que sea aprobada.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
