import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../home_map_view_model.dart';

/// Fila de filtros: categoría de evento y, solo en la App 5 (Visión Global),
/// denominación (varias) (RF-5.5). En las Apps 1 a 4 no hay chips de
/// denominación porque la app muestra una sola.
class FiltrosMapa extends StatelessWidget {
  const FiltrosMapa({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeMapViewModel>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _ChipCategoria(vm: vm),
          for (final d in vm.denominacionesFiltrables)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: FilterChip(
                backgroundColor: Colors.white,
                selected: vm.denominaciones.contains(d),
                onSelected: (_) => vm.alternarDenominacion(d),
                avatar: CircleAvatar(
                  radius: 6,
                  backgroundColor: AppTheme.colorDenominacion(d),
                ),
                label: Text(d.etiquetaCorta),
                tooltip: d.label,
              ),
            ),
          if (vm.hayFiltros)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ActionChip(
                backgroundColor: Colors.white,
                avatar: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Quitar filtros'),
                onPressed: vm.limpiarFiltros,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  const _ChipCategoria({required this.vm});

  final HomeMapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final seleccionada = vm.categoria;
    return InputChip(
      backgroundColor: Colors.white,
      selected: seleccionada != null,
      avatar: const Icon(Icons.sell_outlined, size: 16),
      label: Text(seleccionada ?? 'Categoría'),
      onPressed: () => _elegir(context),
      onDeleted: seleccionada == null ? null : () => vm.elegirCategoria(null),
      deleteButtonTooltipMessage: 'Quitar categoría',
    );
  }

  Future<void> _elegir(BuildContext context) async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Mostrar iglesias con eventos de la categoría…',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Todas las categorías'),
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final c in vm.categorias)
              ListTile(
                leading: Icon(
                  c == vm.categoria
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(c),
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (elegida == null) return;
    vm.elegirCategoria(elegida.isEmpty ? null : elegida);
  }
}
