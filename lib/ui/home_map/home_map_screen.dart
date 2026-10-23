import 'package:flutter/material.dart';
import '../../core/config/terminologia.dart';
import '../shared/widgets/linea_procedencia.dart';
import '../shared/widgets/chip_estado_administracion.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import '../../core/routing/crear_evento_args.dart';
import '../../core/utils/ubicacion_dispositivo.dart';
import '../../data/models/enums.dart';
import '../../data/models/iglesia_model.dart';
import '../shared/map/controlador_mapa.dart';
import '../shared/map/coordenada_mapa.dart';
import '../shared/map/mapa_iglesias.dart';
import '../shared/widgets/banner_modo_demo.dart';
import '../shared/widgets/chip_pendiente.dart';
import '../shared/widgets/mensaje_error.dart';
import 'home_map_view_model.dart';
import 'widgets/boton_cuenta.dart';
import 'widgets/eventos_bottom_sheet.dart';
import 'widgets/filtros_mapa.dart';
import 'widgets/lista_iglesias_sheet.dart';

/// Pantalla principal: mapa de iglesias con clustering, buscador, filtros y
/// botón para crear iglesias, ministerios o eventos (RF-5.1, RF-5.2, RF-5.5).
class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final ControladorMapa _mapa = ControladorMapa();
  final TextEditingController _buscador = TextEditingController();
  final FocusNode _focoBuscador = FocusNode();

  @override
  void initState() {
    super.initState();
    _focoBuscador.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _buscador.dispose();
    _focoBuscador.dispose();
    super.dispose();
  }

  // ---------- Acciones ----------
  void _abrirIglesia(IglesiaModel iglesia) {
    _focoBuscador.unfocus();
    final u = iglesia.ubicacion;
    if (iglesia.esFisica && u != null) {
      _mapa.moverA(CoordenadaMapa(u.latitude, u.longitude), zoom: 15);
    }
    EventosBottomSheet.mostrar(context, iglesia);
  }

  void _alTocarPin(String id) {
    final iglesia = context.read<HomeMapViewModel>().iglesiaPorId(id);
    if (iglesia != null) _abrirIglesia(iglesia);
  }

  Future<void> _ubicarme() async {
    final vm = context.read<HomeMapViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final c = await vm.ubicarme();
      _mapa.moverA(c, zoom: 15);
    } on UbicacionNoDisponible catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  Future<void> _verLista() async {
    final vm = context.read<HomeMapViewModel>();
    final elegida = await ListaIglesiasSheet.mostrar(context, vm);
    if (elegida != null && mounted) _abrirIglesia(elegida);
  }

  Future<void> _crear() async {
    final terminologia = context.read<HomeMapViewModel>().terminologia;
    final opcion = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.church),
              title: const Text('Nueva iglesia'),
              subtitle: const Text(
                  'Física (con pin en el mapa) o virtual. Antes, búscala en '
                  'el mapa: si ya está, ábrela y usa "Reclamar / gestionar '
                  'esta iglesia".'),
              onTap: () => Navigator.of(context).pop('iglesia'),
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Nuevo ministerio'),
              subtitle: const Text('De una iglesia, independiente o virtual'),
              onTap: () => Navigator.of(context).pop('ministerio'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Nuevo evento'),
              subtitle: Text(
                  '${terminologia.resumenTiposActividad}; puede repetirse'),
              onTap: () => Navigator.of(context).pop('evento'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (opcion == null || !mounted) return;
    if (!await AppRouter.requerirSesion(context) || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (opcion == 'iglesia') {
      final id = await navigator.pushNamed<String>(AppRouter.crearIglesia);
      if (id == null || !mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text(
            'Iglesia creada. Queda Pendiente de aprobación (solo tú la ves).'),
      ));
      final nueva = context.read<HomeMapViewModel>().iglesiaPorId(id);
      if (nueva != null) _abrirIglesia(nueva);
    } else if (opcion == 'ministerio') {
      final id = await navigator.pushNamed<String>(AppRouter.crearMinisterio);
      if (id == null || !mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Ministerio creado. Eres su Administrador de Ministerio; '
            'queda Pendiente de aprobación.'),
      ));
    } else {
      final creados = await navigator.pushNamed<int>(
        AppRouter.crearEvento,
        arguments: const CrearEventoArgs(),
      );
      if (creados != null && creados > 0) {
        messenger.showSnackBar(SnackBar(
          content: Text(creados == 1
              ? 'Evento creado. Queda Pendiente de aprobación.'
              : 'Se crearon $creados eventos. Quedan Pendientes de aprobación.'),
        ));
      }
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeMapViewModel>();
    final mostrarResultados =
        _focoBuscador.hasFocus && vm.texto.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapaIglesias(
              marcadores: vm.marcadoresPara(
                  esAdmin: context.watch<AuthViewModel>().esAdmin),
              centroInicial: HomeMapViewModel.centroLima,
              zoomInicial: AppConstants.zoomInicialMapa,
              controlador: _mapa,
              ubicacionUsuario: vm.miUbicacion,
              onMarcadorTap: _alTocarPin,
              onMapaTap: (_) => _focoBuscador.unfocus(),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _barraBusqueda(vm),
                if (vm.cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                const SizedBox(height: 6),
                const FiltrosMapa(),
                if (mostrarResultados) _resultados(vm),
                const SizedBox(height: 6),
                const Center(child: BannerModoDemo()),
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Card(
                      child: MensajeError(
                          mensaje: vm.error!, alReintentar: vm.reintentar),
                    ),
                  ),
                if (!vm.cargando &&
                    vm.error == null &&
                    vm.hayFiltros &&
                    vm.marcadores.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Ninguna iglesia del mapa coincide con los filtros.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'ubicarme',
            tooltip: 'Mi ubicación',
            onPressed: vm.buscandoUbicacion ? null : _ubicarme,
            child: vm.buscandoUbicacion
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'lista',
            tooltip: 'Ver lista de iglesias',
            onPressed: _verLista,
            child: const Icon(Icons.list),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'crear',
            onPressed: _crear,
            icon: const Icon(Icons.add),
            label: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Widget _barraBusqueda(HomeMapViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _buscador,
                focusNode: _focoBuscador,
                textInputAction: TextInputAction.search,
                onChanged: vm.buscar,
                decoration: const InputDecoration(
                  hintText: 'Buscar iglesia, distrito o evento…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            if (vm.texto.isNotEmpty)
              IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _buscador.clear();
                  vm.buscar('');
                },
              ),
            const BotonCuenta(),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _resultados(HomeMapViewModel vm) {
    final lista = vm.iglesiasFiltradas.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: lista.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sin resultados.'),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final i in lista)
                    ListTile(
                      dense: true,
                      leading: Icon(i.esFisica ? Icons.place : Icons.language),
                      title: Text(i.nombre,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i.direccionTexto ?? i.denominacion.etiquetaCorta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          LineaProcedencia(
                            iglesia: i,
                            terminologia: context.read<Terminologia>(),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: i.estadoAprobacion == EstadoAprobacion.pendiente
                          ? const ChipPendiente()
                          : ChipEstadoAdministracion(
                              iglesia: i,
                              terminologia: context.read<Terminologia>(),
                            ),
                      onTap: () => _abrirIglesia(i),
                    ),
                ],
              ),
      ),
    );
  }
}
