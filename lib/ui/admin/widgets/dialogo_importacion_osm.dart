import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_flavor.dart';
import '../../../data/repositories/importacion_iglesias_repository.dart';
import '../importacion_osm_view_model.dart';

/// Diálogo "Importar iglesias de OpenStreetMap" con progreso y conteo.
class DialogoImportacionOsm extends StatelessWidget {
  const DialogoImportacionOsm({super.key});

  static Future<void> mostrar(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider(
        create: (c) => ImportacionOsmViewModel(
          importacionRepository: context.read<ImportacionIglesiasRepository>(),
          fuentes: context.read<AppFlavor>().fuentesImportacionOsm,
        ),
        child: const DialogoImportacionOsm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ImportacionOsmViewModel>();
    final tema = Theme.of(context);
    final r = vm.resultado;
    return AlertDialog(
      title: const Text('Importar iglesias de OpenStreetMap'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vm.descripcion),
            if (vm.importando) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: vm.progreso),
              const SizedBox(height: 6),
              Text(vm.total == 0
                  ? 'Preparando…'
                  : '${vm.procesadas} de ${vm.total} iglesias'),
            ],
            if (r != null) ...[
              const SizedBox(height: 16),
              Text(
                  'Listo: ${r.creadas} iglesias nuevas · '
                  '${r.yaExistian} ya estaban · ${r.total} en el archivo.',
                  style: tema.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (r.porVerificar > 0) ...[
                const SizedBox(height: 6),
                Text('${r.porVerificar} de las nuevas tienen la denominación '
                    'deducida por el nombre: revísalas en la pestaña '
                    '"Por verificar".'),
              ],
              const SizedBox(height: 8),
              Text('Datos: ${r.atribucion} (ODbL).',
                  style: tema.textTheme.bodySmall),
            ],
            if (vm.error != null) ...[
              const SizedBox(height: 12),
              Text(vm.error!, style: TextStyle(color: tema.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: vm.importando ? null : () => Navigator.of(context).pop(),
          child: Text(r != null ? 'Cerrar' : 'Cancelar'),
        ),
        if (r == null)
          FilledButton.icon(
            onPressed: vm.importando || !vm.hayFuentes ? null : vm.importar,
            icon: const Icon(Icons.download),
            label: const Text('Importar'),
          ),
      ],
    );
  }
}
