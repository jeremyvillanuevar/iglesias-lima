import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/iglesia_model.dart';
import '../../shared/layout/margenes_sistema.dart';
import '../../../core/config/terminologia.dart';
import '../../shared/widgets/chip_estado_administracion.dart';
import '../../shared/widgets/chip_pendiente.dart';
import '../../shared/widgets/linea_procedencia.dart';
import '../home_map_view_model.dart';

/// Lista de las iglesias filtradas (incluye las virtuales, que no tienen pin).
/// Devuelve la iglesia elegida.
class ListaIglesiasSheet extends StatelessWidget {
  const ListaIglesiasSheet({super.key, required this.vm});

  final HomeMapViewModel vm;

  static Future<IglesiaModel?> mostrar(
      BuildContext context, HomeMapViewModel vm) {
    return showModalBottomSheet<IglesiaModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ListaIglesiasSheet(vm: vm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iglesias = vm.iglesiasFiltradas;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  '${iglesias.length} iglesia${iglesias.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (vm.hayFiltros) const Text('  (con filtros)'),
              ],
            ),
          ),
          Expanded(
            child: iglesias.isEmpty
                ? const Center(
                    child: Text('Ninguna iglesia coincide con la búsqueda.'))
                : ListView.separated(
                    controller: scroll,
                    padding: MargenesSistema.lista(context, arriba: 0),
                    itemCount: iglesias.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final ig = iglesias[i];
                      final n = vm.eventosProximosDe(ig.idIglesia);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.colorDenominacion(ig.denominacion),
                          child: Icon(
                              ig.esFisica ? Icons.church : Icons.language,
                              color: Colors.white,
                              size: 20),
                        ),
                        title: Text(ig.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text([
                              ig.denominacion.etiquetaCorta,
                              if (!ig.esFisica) 'Virtual',
                              '$n evento${n == 1 ? '' : 's'} próximos',
                            ].join(' · ')),
                            LineaProcedencia(
                              iglesia: ig,
                              terminologia: context.read<Terminologia>(),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: ChipEstadoAdministracion(
                                iglesia: ig,
                                terminologia: context.read<Terminologia>(),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing:
                            ig.estadoAprobacion == EstadoAprobacion.pendiente
                                ? const ChipPendiente()
                                : const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(ig),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
