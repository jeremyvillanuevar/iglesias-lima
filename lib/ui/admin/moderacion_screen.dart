import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/terminologia.dart';
import '../../core/utils/formato_fechas.dart';
import '../../data/models/enums.dart';
import '../../data/models/evento_model.dart';
import '../../data/models/iglesia_model.dart';
import '../../data/models/ministerio_model.dart';
import '../../data/models/solicitud_reclamo_model.dart';
import '../shared/layout/margenes_sistema.dart';
import '../shared/widgets/cargando.dart';
import '../shared/widgets/chip_estado_administracion.dart';
import '../shared/widgets/chip_por_verificar.dart';
import '../shared/widgets/linea_procedencia.dart';
import '../shared/widgets/mensaje_error.dart';
import 'moderacion_view_model.dart';
import 'widgets/dialogo_importacion_osm.dart';
import 'widgets/tarjeta_moderacion.dart';

/// Moderación (Admin General y Pastor/Padre): pestañas de Iglesias,
/// Ministerios y Eventos Pendientes con Aprobar / Rechazar / Borrar. El
/// Administrador General ve además "Reclamos" y puede importar iglesias de
/// OpenStreetMap.
class ModeracionScreen extends StatelessWidget {
  const ModeracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ModeracionViewModel>();
    final conReclamos = vm.puedeModerar && vm.muestraReclamos;
    return DefaultTabController(
      // La cantidad de pestañas cambia si el perfil pasa a Admin General.
      key: ValueKey(conReclamos),
      length: conReclamos ? 5 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderación'),
          actions: [
            if (conReclamos)
              IconButton(
                tooltip: 'Importar iglesias de OpenStreetMap',
                icon: const Icon(Icons.cloud_download_outlined),
                onPressed: () => DialogoImportacionOsm.mostrar(context),
              ),
          ],
          bottom: vm.puedeModerar
              ? TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'Iglesias (${vm.iglesias.length})'),
                    Tab(text: 'Ministerios (${vm.ministerios.length})'),
                    Tab(text: 'Eventos (${vm.eventos.length})'),
                    if (conReclamos)
                      Tab(text: 'Reclamos (${vm.reclamos.length})'),
                    if (conReclamos)
                      Tab(text: 'Por verificar (${vm.totalPorVerificar})'),
                  ],
                )
              : null,
        ),
        body: _cuerpo(context, vm),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, ModeracionViewModel vm) {
    if (vm.cargandoPerfil) return const Cargando(mensaje: 'Cargando…');
    if (!vm.puedeModerar) {
      return MensajeError(
        icono: Icons.lock_outline,
        mensaje: vm.mensajeSinPermiso,
      );
    }
    if (vm.error != null) {
      return MensajeError(mensaje: vm.error!, alReintentar: vm.reintentar);
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(vm.descripcionAlcance,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _lista<IglesiaModel>(
                context,
                cargando: vm.cargandoIglesias,
                elementos: vm.iglesias,
                vacio: 'No hay iglesias pendientes.',
                tarjeta: (i) => _tarjetaIglesia(context, vm, i),
              ),
              _lista<MinisterioModel>(
                context,
                cargando: vm.cargandoMinisterios,
                elementos: vm.ministerios,
                vacio: 'No hay ministerios pendientes.',
                tarjeta: (m) => _tarjetaMinisterio(context, vm, m),
              ),
              _lista<EventoModel>(
                context,
                cargando: vm.cargandoEventos,
                elementos: vm.eventos,
                vacio: 'No hay eventos pendientes.',
                tarjeta: (e) => _tarjetaEvento(context, vm, e),
              ),
              if (vm.muestraReclamos)
                _lista<SolicitudReclamoModel>(
                  context,
                  cargando: vm.cargandoReclamos,
                  elementos: vm.reclamos,
                  vacio: 'No hay reclamos de iglesias pendientes.',
                  tarjeta: (r) => _tarjetaReclamo(context, vm, r),
                ),
              if (vm.muestraReclamos) _pestanaPorVerificar(context, vm),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lista<T>(
    BuildContext context, {
    required bool cargando,
    required List<T> elementos,
    required String vacio,
    required Widget Function(T) tarjeta,
  }) {
    if (cargando) return const Cargando(mensaje: 'Buscando pendientes…');
    if (elementos.isEmpty) {
      return MensajeError(icono: Icons.task_alt, mensaje: vacio);
    }
    return ListView.builder(
      // Margen inferior: los botones de la última tarjeta no deben quedar
      // debajo de la barra de navegación del sistema.
      padding: MargenesSistema.lista(context, arriba: 8),
      itemCount: elementos.length,
      itemBuilder: (_, i) => tarjeta(elementos[i]),
    );
  }

  Widget _tarjetaIglesia(
      BuildContext context, ModeracionViewModel vm, IglesiaModel i) {
    return TarjetaModeracion(
      icono: i.esFisica ? Icons.church : Icons.language,
      titulo: i.nombre,
      detalle: _DetalleIglesia(iglesia: i, terminologia: vm.terminologia),
      lineas: [
        '${i.denominacion.etiquetaCorta} · ${i.esFisica ? 'Física' : 'Virtual'}',
        if (i.direccionTexto != null) i.direccionTexto!,
        if (i.linkVirtual != null) i.linkVirtual!,
        '${i.localidad}, ${i.pais}',
        if (i.liderNombreTexto != null) 'A cargo: ${i.liderNombreTexto}',
        if (i.creadoEn != null)
          'Propuesta el ${FormatoFechas.fecha(i.creadoEn!)}',
      ],
      ocupado: vm.enProceso(i.idIglesia),
      esPropio: vm.esPropioSinPermiso(i.creadoPor),
      alAprobar: () =>
          _accion(context, vm.aprobarIglesia(i.idIglesia), 'Iglesia aprobada.'),
      alRechazar: () => _confirmarYRechazar(
          context, i.nombre, () => vm.rechazarIglesia(i.idIglesia)),
      alBorrar: vm.puedeBorrarDefinitivamente
          ? () => _confirmarYBorrar(
              context, i.nombre, () => vm.borrarIglesia(i.idIglesia))
          : null,
    );
  }

  Widget _tarjetaMinisterio(
      BuildContext context, ModeracionViewModel vm, MinisterioModel m) {
    final matriz = vm.nombreIglesia(m.iglesiaRef);
    return TarjetaModeracion(
      icono: Icons.groups,
      titulo: m.nombre,
      lineas: [
        switch (m.tipoUbicacion) {
          TipoUbicacionMinisterio.iglesia => 'De la iglesia: ${matriz ?? '…'}',
          TipoUbicacionMinisterio.fisica =>
            'Independiente con sede propia${m.localidad != null ? ' · ${m.localidad}, ${m.pais ?? ''}' : ''}',
          TipoUbicacionMinisterio.virtual =>
            'Independiente virtual · ${m.linkVirtual ?? ''}',
        },
        if (m.denominacion != null) m.denominacion!.etiquetaCorta,
        if (m.creadoEn != null)
          'Propuesto el ${FormatoFechas.fecha(m.creadoEn!)}',
      ],
      ocupado: vm.enProceso(m.idMinisterio),
      esPropio: vm.esPropioSinPermiso(m.creadoPor),
      alAprobar: () => _accion(context, vm.aprobarMinisterio(m.idMinisterio),
          'Ministerio aprobado.'),
      alRechazar: () => _confirmarYRechazar(
          context, m.nombre, () => vm.rechazarMinisterio(m.idMinisterio)),
      alBorrar: vm.puedeBorrarDefinitivamente
          ? () => _confirmarYBorrar(
              context, m.nombre, () => vm.borrarMinisterio(m.idMinisterio))
          : null,
    );
  }

  Widget _tarjetaEvento(
      BuildContext context, ModeracionViewModel vm, EventoModel e) {
    final iglesia = vm.nombreIglesia(e.iglesiaRef);
    return TarjetaModeracion(
      icono: Icons.event,
      titulo: e.titulo,
      lineas: [
        '${e.tipoActividad.label} · ${e.categoria}',
        FormatoFechas.diaYHora(e.fechaHoraInicio),
        if (e.iglesiaRef != null) 'En: ${iglesia ?? '…'}',
        if (e.esVirtual) 'Virtual · ${e.linkVirtual ?? ''}',
        if (e.descripcion != null) e.descripcion!,
      ],
      ocupado: vm.enProceso(e.idEvento),
      esPropio: vm.esPropioSinPermiso(e.creadoPor),
      alAprobar: () =>
          _accion(context, vm.aprobarEvento(e.idEvento), 'Evento aprobado.'),
      alRechazar: () => _confirmarYRechazar(
          context, e.titulo, () => vm.rechazarEvento(e.idEvento)),
      alBorrar: vm.puedeBorrarDefinitivamente
          ? () => _confirmarYBorrar(
              context, e.titulo, () => vm.borrarEvento(e.idEvento))
          : null,
    );
  }

  /// Importadas de OSM cuya denominación solo se dedujo por el nombre.
  Widget _pestanaPorVerificar(BuildContext context, ModeracionViewModel vm) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            onChanged: vm.filtrarPorVerificar,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.filter_list),
              hintText: 'Filtrar por nombre o distrito',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        _FiltroCriterio(vm: vm),
        Expanded(
          child: _lista<IglesiaModel>(
            context,
            cargando: vm.cargandoPorVerificar,
            elementos: vm.porVerificar,
            vacio:
                vm.filtroPorVerificar.isEmpty && vm.criterioPorVerificar == null
                    ? 'No hay iglesias importadas por verificar.'
                    : 'Ninguna coincide con el filtro.',
            tarjeta: (i) => _tarjetaPorVerificar(context, vm, i),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaPorVerificar(
      BuildContext context, ModeracionViewModel vm, IglesiaModel i) {
    final texto = i.sinMarcador
        ? 'Sin etiqueta de denominación ni marca en el nombre: revisa si es '
            '"${i.denominacion.etiquetaCorta}".'
        : 'Sin etiqueta de denominación: se dedujo '
            '"${i.denominacion.etiquetaCorta}" por el nombre.';
    return TarjetaModeracion(
      icono: Icons.help_outline,
      titulo: i.nombre,
      insignia: ChipPorVerificar(sinMarcador: i.sinMarcador),
      detalle: _DetalleIglesia(iglesia: i, terminologia: vm.terminologia),
      lineas: [
        texto,
        if (i.direccionTexto != null) i.direccionTexto!,
        if (i.osmId != null) 'OSM: ${i.osmId}',
      ],
      ocupado: vm.enProceso(i.idIglesia),
      esPropio: false,
      textoAprobar: 'Confirmar',
      textoRechazar: 'Descartar',
      alAprobar: () => _accion(context, vm.confirmarDenominacion(i.idIglesia),
          'Denominación confirmada.'),
      alRechazar: () => _confirmarYDescartar(
          context, i.nombre, () => vm.descartarPorVerificar(i.idIglesia)),
    );
  }

  Widget _tarjetaReclamo(
      BuildContext context, ModeracionViewModel vm, SolicitudReclamoModel r) {
    return TarjetaModeracion(
      icono: Icons.how_to_reg_outlined,
      titulo: r.nombreIglesia,
      lineas: [
        'Solicita administrarla: ${r.nombreSolicitante} (${r.emailSolicitante})',
        'Cargo: ${r.cargo}',
        if (r.mensaje != null) 'Mensaje: ${r.mensaje}',
        r.denominacion.etiquetaCorta,
        if (r.creadoEn != null)
          'Enviado el ${FormatoFechas.fecha(r.creadoEn!)}',
      ],
      ocupado: vm.enProceso(r.idSolicitud),
      esPropio: false,
      alAprobar: () => _accion(context, vm.aprobarReclamo(r.idSolicitud),
          'Reclamo aprobado: ${r.nombreSolicitante} ya administra la iglesia.'),
      alRechazar: () => _confirmarYRechazar(
          context,
          'Reclamo de ${r.nombreSolicitante}',
          () => vm.rechazarReclamo(r.idSolicitud)),
    );
  }

  // ---------- Diálogos y mensajes ----------
  Future<void> _accion(
      BuildContext context, Future<String?> resultado, String exito) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorError = Theme.of(context).colorScheme.error;
    final error = await resultado;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error ?? exito),
        backgroundColor: error == null ? null : colorError,
      ));
  }

  Future<void> _confirmarYRechazar(BuildContext context, String nombre,
      Future<String?> Function() rechazar) async {
    final ok = await _confirmar(
      context,
      titulo: 'Rechazar',
      mensaje: '"$nombre" quedará Rechazado y no se publicará.',
      boton: 'Rechazar',
    );
    if (ok && context.mounted) await _accion(context, rechazar(), 'Rechazado.');
  }

  Future<void> _confirmarYBorrar(BuildContext context, String nombre,
      Future<String?> Function() borrar) async {
    final ok = await _confirmar(
      context,
      titulo: 'Borrar definitivamente',
      mensaje: '"$nombre" se eliminará de la base de datos. '
          'Esta acción no se puede deshacer.',
      boton: 'Borrar',
      peligroso: true,
    );
    if (ok && context.mounted) {
      await _accion(context, borrar(), 'Borrado definitivamente.');
    }
  }

  Future<void> _confirmarYDescartar(BuildContext context, String nombre,
      Future<String?> Function() descartar) async {
    final ok = await _confirmar(
      context,
      titulo: 'Descartar iglesia importada',
      mensaje: '"$nombre" se borrará del mapa y no se volverá a importar. '
          'Esta acción no se puede deshacer.',
      boton: 'Descartar',
      peligroso: true,
    );
    if (ok && context.mounted) {
      await _accion(context, descartar(), 'Iglesia descartada.');
    }
  }

  Future<bool> _confirmar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required String boton,
    bool peligroso = false,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: peligroso
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(boton),
          ),
        ],
      ),
    );
    return r == true;
  }
}

class _DetalleIglesia extends StatelessWidget {
  const _DetalleIglesia({required this.iglesia, required this.terminologia});

  final IglesiaModel iglesia;
  final Terminologia terminologia;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        LineaProcedencia(iglesia: iglesia, terminologia: terminologia),
        ChipEstadoAdministracion(iglesia: iglesia, terminologia: terminologia),
      ],
    );
  }
}

class _FiltroCriterio extends StatelessWidget {
  const _FiltroCriterio({required this.vm});

  final ModeracionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final actual = vm.criterioPorVerificar;
    Widget chip(String label, CriterioOsm? c) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(label),
            selected: actual == c,
            onSelected: (_) => vm.filtrarPorCriterio(c),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          chip('Todas (${vm.totalPorVerificar})', null),
          chip(
              'Por el nombre (${vm.totalPorVerificarCon(CriterioOsm.porNombre)})',
              CriterioOsm.porNombre),
          chip(
              'Sin marcador (${vm.totalPorVerificarCon(CriterioOsm.sinMarcador)})',
              CriterioOsm.sinMarcador),
        ],
      ),
    );
  }
}
