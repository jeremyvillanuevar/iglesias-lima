import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/formato_fechas.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';
import '../../data/recurrencia/frecuencia_recurrencia.dart';
import '../../data/recurrencia/hora_del_dia.dart';
import 'crear_evento_view_model.dart';
import 'widgets/selector_turnos.dart';
import 'widgets/vista_previa_recurrencia.dart';

/// Formulario de evento: nuevo o clonado (RF-4.3, RF-4.4).
/// Al hacer pop devuelve cuántos eventos se crearon.
class CrearEventoScreen extends StatefulWidget {
  const CrearEventoScreen({super.key});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late final TextEditingController _link;
  late final TextEditingController _imagen;
  late final TextEditingController _repeticiones;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CrearEventoViewModel>();
    _titulo = TextEditingController(text: vm.tituloInicial);
    _descripcion = TextEditingController(text: vm.descripcionInicial);
    _link = TextEditingController(text: vm.linkInicial);
    _imagen = TextEditingController(text: vm.imagenInicial);
    _repeticiones = TextEditingController(text: '${vm.repeticiones}');
  }

  @override
  void dispose() {
    for (final c in [_titulo, _descripcion, _link, _imagen, _repeticiones]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha(CrearEventoViewModel vm) async {
    final f = await showDatePicker(
      context: context,
      initialDate: vm.fecha,
      firstDate: vm.hoy,
      lastDate: vm.fechaMaxima,
      helpText: 'Fecha del evento',
    );
    if (f != null) vm.cambiarFecha(f);
  }

  Future<void> _elegirFechaFin(CrearEventoViewModel vm) async {
    final f = await showDatePicker(
      context: context,
      initialDate: vm.fechaFin.isBefore(vm.fecha) ? vm.fecha : vm.fechaFin,
      firstDate: vm.fecha,
      lastDate: vm.fechaMaxima,
      helpText: 'Repetir hasta',
    );
    if (f != null) vm.cambiarFechaFin(f);
  }

  Future<void> _agregarHora(CrearEventoViewModel vm) async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Agregar hora',
    );
    if (t != null) vm.agregarTurno(HoraDelDia(t.hour, t.minute));
  }

  Future<void> _guardar() async {
    final vm = context.read<CrearEventoViewModel>();
    if (!_formKey.currentState!.validate()) return;
    final creados = await vm.guardar(
      titulo: _titulo.text,
      descripcion: _descripcion.text,
      linkVirtual: _link.text,
      imagenUrl: _imagen.text,
    );
    if (creados != null && mounted) Navigator.of(context).pop(creados);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrearEventoViewModel>();
    final tema = Theme.of(context);
    final vista = vm.vistaPrevia;
    final cantidad = vista?.cantidad ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(vm.esClon ? 'Clonar evento' : 'Nuevo evento')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (vm.esClon)
                Card(
                  color: tema.colorScheme.secondaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.copy_all_outlined),
                    title: Text('Clonando: ${vm.eventoBase!.titulo}'),
                    subtitle: const Text(
                        'Revisa la fecha y la hora antes de guardar.'),
                  ),
                ),
              const SizedBox(height: 8),
              _seccion('¿Dónde?'),
              _selectorIglesia(vm),
              const SizedBox(height: 16),
              _seccion('¿Qué?'),
              SegmentedButton<TipoActividad>(
                segments: [
                  for (final t in vm.tiposActividad)
                    ButtonSegment(value: t, label: Text(t.label)),
                ],
                selected: {vm.tipoActividad},
                onSelectionChanged: (s) => vm.cambiarTipoActividad(s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titulo,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  hintText: vm.terminologia.ejemploTituloEvento,
                ),
                validator: (v) => Validators.requerido(v, campo: 'El título'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: vm.categoria,
                decoration: const InputDecoration(labelText: 'Categoría *'),
                items: [
                  for (final c in vm.categorias)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: vm.cambiarCategoria,
                validator: (v) => v == null ? 'Elige una categoría.' : null,
              ),
              const SizedBox(height: 16),
              _seccion('¿Cuándo?'),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text(vm.seRepite ? 'Primera fecha *' : 'Fecha *'),
                  subtitle: Text(FormatoFechas.diaLargo(vm.fecha)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _elegirFecha(vm),
                ),
              ),
              const SizedBox(height: 12),
              Text('Hora(s) *  — puedes elegir varios turnos el mismo día',
                  style: tema.textTheme.bodySmall),
              const SizedBox(height: 6),
              SelectorTurnos(
                seleccionados: vm.turnos,
                rapidos: CrearEventoViewModel.turnosRapidos,
                onAlternar: vm.alternarTurno,
                onQuitar: vm.quitarTurno,
                onAgregar: () => _agregarHora(vm),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Duration?>(
                isExpanded: true,
                initialValue: vm.duracion,
                decoration:
                    const InputDecoration(labelText: 'Duración (opcional)'),
                items: [
                  for (final d in CrearEventoViewModel.duraciones)
                    DropdownMenuItem(value: d, child: Text(_textoDuracion(d))),
                ],
                onChanged: vm.cambiarDuracion,
              ),
              const SizedBox(height: 16),
              _seccion('¿Se repite?'),
              DropdownButtonFormField<FrecuenciaRecurrencia>(
                isExpanded: true,
                initialValue: vm.frecuencia,
                decoration: const InputDecoration(
                  labelText: 'Repetición',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: [
                  for (final f in FrecuenciaRecurrencia.values)
                    DropdownMenuItem(value: f, child: Text(f.label)),
                ],
                onChanged: (f) {
                  if (f != null) vm.cambiarFrecuencia(f);
                },
              ),
              if (vm.seRepite) ...[
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: false, label: Text('Cantidad de veces')),
                    ButtonSegment(value: true, label: Text('Hasta una fecha')),
                  ],
                  selected: {vm.terminaPorFecha},
                  onSelectionChanged: (s) => vm.cambiarTerminaPorFecha(s.first),
                ),
                const SizedBox(height: 12),
                if (vm.terminaPorFecha)
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: const Text('Repetir hasta (inclusive)'),
                      subtitle: Text(FormatoFechas.diaLargo(vm.fechaFin)),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () => _elegirFechaFin(vm),
                    ),
                  )
                else
                  TextFormField(
                    controller: _repeticiones,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de fechas',
                      helperText: 'Ej. 4 = cuatro semanas si es semanal',
                    ),
                    validator: (v) => Validators.enteroEnRango(v,
                        min: 1, max: AppConstants.maxRepeticionesFormulario),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) vm.cambiarRepeticiones(n);
                    },
                  ),
              ],
              const SizedBox(height: 12),
              VistaPreviaRecurrencia(
                resultado: vista,
                horariosPasados: vm.horariosPasados,
              ),
              const SizedBox(height: 16),
              _seccion('Modalidad'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: vm.esVirtual,
                onChanged: vm.virtualBloqueado ? null : vm.cambiarVirtual,
                title: const Text('Evento virtual'),
                subtitle: Text(vm.virtualBloqueado
                    ? 'La iglesia es virtual, así que el evento también.'
                    : 'Se transmite o se realiza por internet'),
              ),
              _infoPin(vm),
              if (vm.esVirtual) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Enlace del evento (URL) *',
                    hintText:
                        'https://youtube.com/… o https://meet.google.com/…',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: Validators.url,
                ),
              ],
              const SizedBox(height: 16),
              _seccion('Detalles (opcional)'),
              TextFormField(
                controller: _descripcion,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imagen,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Imagen (URL)',
                  hintText: 'https://…/afiche.jpg',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                validator: Validators.urlOpcional,
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
                label: Text(
                    cantidad > 1 ? 'Crear $cantidad eventos' : 'Crear evento'),
              ),
              const SizedBox(height: 6),
              const Text(
                'Los eventos nuevos quedan "Pendientes" hasta que el aprobador los revise.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      );

  Widget _selectorIglesia(CrearEventoViewModel vm) {
    if (vm.cargandoIglesias) return const LinearProgressIndicator();
    if (vm.iglesias.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Todavía no hay iglesias disponibles.'),
          subtitle:
              const Text('Primero registra la iglesia donde será el evento.'),
          trailing: TextButton(
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed(AppRouter.crearIglesia),
            child: const Text('Crear iglesia'),
          ),
        ),
      );
    }
    final existe = vm.iglesias.any((i) => i.idIglesia == vm.idIglesia);
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: existe ? vm.idIglesia : null,
      decoration: const InputDecoration(
        labelText: 'Iglesia *',
        prefixIcon: Icon(Icons.church_outlined),
      ),
      items: [
        for (final i in vm.iglesias)
          DropdownMenuItem(
            value: i.idIglesia,
            child: Text(
              '${i.nombre}${i.estadoAprobacion == EstadoAprobacion.pendiente ? ' (Pendiente)' : ''}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: vm.elegirIglesia,
      validator: (v) => v == null ? 'Elige la iglesia.' : null,
    );
  }

  Widget _infoPin(CrearEventoViewModel vm) {
    final iglesia = vm.iglesiaSeleccionada;
    final deshabilitado = vm.esVirtual;
    return Card(
      margin: EdgeInsets.zero,
      color: deshabilitado ? const Color(0xFFF0F0F0) : null,
      child: ListTile(
        enabled: !deshabilitado,
        leading:
            Icon(deshabilitado ? Icons.location_off_outlined : Icons.place),
        title:
            Text(deshabilitado ? 'Pin del mapa deshabilitado' : 'Pin del mapa'),
        subtitle: Text(deshabilitado
            ? 'Al ser virtual, el evento no usa ubicación física: se exige un enlace.'
            : (iglesia == null
                ? 'Se mostrará en el pin de la iglesia que elijas.'
                : 'Se mostrará en el pin de "${iglesia.nombre}".')),
      ),
    );
  }

  String _textoDuracion(Duration? d) {
    if (d == null) return 'Sin hora de fin';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '$m minutos';
    if (m == 0) return h == 1 ? '1 hora' : '$h horas';
    return '$h h $m min';
  }
}
