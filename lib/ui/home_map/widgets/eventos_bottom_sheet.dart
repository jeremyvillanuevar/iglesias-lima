import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/terminologia.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/crear_evento_args.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/evento_model.dart';
import '../../../data/models/iglesia_model.dart';
import '../../../data/repositories/evento_repository.dart';
import '../../shared/layout/margenes_sistema.dart';
import '../../shared/widgets/cargando.dart';
import '../../auth/auth_view_model.dart';
import '../../shared/widgets/chip_estado_administracion.dart';
import '../../shared/widgets/chip_pendiente.dart';
import '../../shared/widgets/chip_por_verificar.dart';
import '../../shared/widgets/linea_procedencia.dart';
import '../../shared/widgets/mensaje_error.dart';
import '../eventos_iglesia_view_model.dart';
import 'evento_card.dart';

/// Panel inferior al tocar el pin de una iglesia (RF-5.1): eventos de los
/// próximos 30 días y pestaña "Historial/Vencidos" (máx. 16 meses).
class EventosBottomSheet extends StatelessWidget {
  const EventosBottomSheet({super.key, required this.iglesia});

  final IglesiaModel iglesia;

  /// Abre el panel sobre la pantalla actual.
  static Future<void> mostrar(BuildContext context, IglesiaModel iglesia) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ChangeNotifierProvider(
        create: (c) => EventosIglesiaViewModel(
          eventoRepository: c.read<EventoRepository>(),
          idIglesia: iglesia.idIglesia,
        ),
        child: EventosBottomSheet(iglesia: iglesia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, scroll) => DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _Cabecera(iglesia: iglesia),
            TabBarTheme(
              data: AppTheme.pestanasSobreSuperficie(
                  Theme.of(context).colorScheme),
              child: TabBar(
                onTap: (i) {
                  if (i == 1) {
                    context.read<EventosIglesiaViewModel>().asegurarHistorial();
                  }
                },
                tabs: const [
                  Tab(text: 'Próximos ${AppConstants.ventanaEventosDias} días'),
                  Tab(text: 'Historial / Vencidos'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ListaProximos(iglesia: iglesia, scroll: scroll),
                  _ListaHistorial(iglesia: iglesia),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre el formulario de evento (nuevo o clonado), pidiendo sesión si hace falta.
Future<void> _abrirFormulario(
  BuildContext context,
  IglesiaModel iglesia, {
  EventoModel? base,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (!await AppRouter.requerirSesion(context)) return;
  final creados = await navigator.pushNamed<int>(
    AppRouter.crearEvento,
    arguments: CrearEventoArgs(idIglesia: iglesia.idIglesia, eventoBase: base),
  );
  if (creados != null && creados > 0) {
    messenger.showSnackBar(SnackBar(
      content: Text(creados == 1
          ? 'Evento creado. Queda Pendiente de aprobación.'
          : 'Se crearon $creados eventos. Quedan Pendientes de aprobación.'),
    ));
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.iglesia});

  final IglesiaModel iglesia;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = AppTheme.colorDenominacion(iglesia.denominacion);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iglesia.esFisica ? Icons.church : Icons.language,
                  color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(iglesia.nombre,
                    style: tema.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(iglesia.denominacion.etiquetaCorta),
                avatar: CircleAvatar(backgroundColor: color, radius: 6),
              ),
              if (iglesia.estadoAprobacion == EstadoAprobacion.pendiente)
                const ChipPendiente(),
              ChipEstadoAdministracion(
                iglesia: iglesia,
                terminologia: context.read<Terminologia>(),
              ),
              if (iglesia.porVerificar &&
                  context.watch<AuthViewModel>().esAdmin)
                ChipPorVerificar(sinMarcador: iglesia.sinMarcador),
            ],
          ),
          const SizedBox(height: 2),
          LineaProcedencia(
            iglesia: iglesia,
            terminologia: context.read<Terminologia>(),
          ),
          if (iglesia.direccionTexto != null)
            _Linea(icono: Icons.place_outlined, texto: iglesia.direccionTexto!),
          if (iglesia.liderNombreTexto != null)
            _Linea(
                icono: Icons.person_outline,
                texto: 'A cargo: ${iglesia.liderNombreTexto!}'),
          Wrap(
            spacing: 8,
            children: [
              if (iglesia.esFisica && iglesia.ubicacion != null)
                TextButton.icon(
                  onPressed: () => _comoLlegar(context),
                  icon: const Icon(Icons.directions),
                  label: const Text('Cómo llegar'),
                ),
              if (iglesia.linkVirtual != null)
                TextButton.icon(
                  onPressed: () => _abrir(context, iglesia.linkVirtual!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Sitio / transmisión'),
                ),
              TextButton.icon(
                onPressed: () => _abrirFormulario(context, iglesia),
                icon: const Icon(Icons.add),
                label: const Text('Agregar evento'),
              ),
              if (context.watch<AuthViewModel>().haySesion &&
                  iglesia.admiteReclamo)
                TextButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRouter.reclamarIglesia, arguments: iglesia),
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: const Text('Reclamar / gestionar esta iglesia'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _comoLlegar(BuildContext context) {
    final u = iglesia.ubicacion!;
    return _abrir(context,
        'https://www.google.com/maps/dir/?api=1&destination=${u.latitude},${u.longitude}');
  }

  Future<void> _abrir(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')));
    }
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16),
          const SizedBox(width: 6),
          Expanded(
              child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _ListaProximos extends StatelessWidget {
  const _ListaProximos({required this.iglesia, required this.scroll});

  final IglesiaModel iglesia;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventosIglesiaViewModel>();
    if (vm.cargandoProximos) {
      return const Cargando(mensaje: 'Cargando eventos…');
    }
    if (vm.errorProximos != null) {
      return MensajeError(mensaje: vm.errorProximos!);
    }
    if (vm.proximos.isEmpty) {
      return ListView(
        controller: scroll,
        padding: MargenesSistema.lista(context),
        children: const [
          SizedBox(height: 24),
          MensajeError(
            icono: Icons.event_busy,
            mensaje: 'No hay eventos en los próximos 30 días.\n'
                'Usa "Agregar evento" para registrar uno.',
          ),
        ],
      );
    }
    return ListView.builder(
      controller: scroll,
      // Margen inferior = barra de navegación del sistema + 24, para que el
      // botón "Clonar Evento" del último evento no quede debajo de ella.
      padding: MargenesSistema.lista(context),
      itemCount: vm.proximos.length,
      itemBuilder: (context, i) {
        final e = vm.proximos[i];
        return EventoCard(
          evento: e,
          onClonar: () => _abrirFormulario(context, iglesia, base: e),
        );
      },
    );
  }
}

class _ListaHistorial extends StatelessWidget {
  const _ListaHistorial({required this.iglesia});

  final IglesiaModel iglesia;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventosIglesiaViewModel>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Mostrar: '),
                for (final m in EventosIglesiaViewModel.opcionesMeses)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(m == 1 ? 'Último mes' : '$m meses'),
                      selected: vm.mesesHistorial == m,
                      onSelected: (_) => vm.cambiarMeses(m),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(child: _contenido(context, vm)),
      ],
    );
  }

  Widget _contenido(BuildContext context, EventosIglesiaViewModel vm) {
    if (vm.historial == null &&
        !vm.cargandoHistorial &&
        vm.errorHistorial == null) {
      // La pestaña se abrió deslizando: se carga ahora.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => vm.asegurarHistorial());
    }
    if (vm.cargandoHistorial || vm.historial == null) {
      if (vm.errorHistorial != null) {
        return MensajeError(
            mensaje: vm.errorHistorial!, alReintentar: vm.cargarHistorial);
      }
      return const Cargando(mensaje: 'Cargando historial…');
    }
    if (vm.errorHistorial != null) {
      return MensajeError(
          mensaje: vm.errorHistorial!, alReintentar: vm.cargarHistorial);
    }
    final lista = vm.historial!;
    if (lista.isEmpty) {
      return const MensajeError(
        icono: Icons.history,
        mensaje: 'No hay eventos pasados en este periodo.',
      );
    }
    return ListView.builder(
      // Margen inferior = barra de navegación del sistema + 24, para que el
      // botón "Clonar Evento" del último evento no quede debajo de ella.
      padding: MargenesSistema.lista(context),
      itemCount: lista.length,
      itemBuilder: (context, i) => EventoCard(
        evento: lista[i],
        vencido: true,
        onClonar: () => _abrirFormulario(context, iglesia, base: lista[i]),
      ),
    );
  }
}
