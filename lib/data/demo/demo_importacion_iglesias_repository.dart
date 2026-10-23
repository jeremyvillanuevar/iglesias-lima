import '../../core/config/fuente_importacion_osm.dart';
import '../importacion/lector_importacion_osm.dart';
import '../importacion/planificador_importacion.dart';
import '../importacion/progreso_importacion.dart';
import '../importacion/resultado_importacion.dart';
import '../models/descarte_osm.dart';
import '../models/enums.dart';
import '../repositories/auth_repository.dart';
import '../repositories/importacion_iglesias_repository.dart';
import '../repositories/permisos_moderacion.dart';
import 'demo_data_store.dart';

/// Importación en memoria (Modo Demo): lee el mismo archivo incluido en la
/// app y agrega al mapa las iglesias que aún no estén.
class DemoImportacionIglesiasRepository
    implements ImportacionIglesiasRepository {
  DemoImportacionIglesiasRepository(
    this._store,
    this._auth, {
    LectorImportacionOsm? lector,
    PlanificadorImportacion planificador = const PlanificadorImportacion(),
  })  : _lector = lector ?? LectorImportacionOsm(),
        _planificador = planificador;

  final DemoDataStore _store;
  final AuthRepository _auth;
  final LectorImportacionOsm _lector;
  final PlanificadorImportacion _planificador;

  @override
  Future<ResultadoImportacion> importarDesdeOsm(
    FuenteImportacionOsm fuente, {
    ProgresoImportacion? alProgresar,
  }) async {
    final miRef = _auth.requerirRefUsuario();
    PermisosModeracion.exigirAdminPara(
        _store.usuarioActual.value, 'importar iglesias de OpenStreetMap');

    final paquete = await _lector.leer(fuente);
    final total = paquete.iglesias.length;
    // Ya importadas (de cualquier denominación) + descartadas para esta.
    final existentes = {
      for (final i in _store.iglesias.value)
        if (i.origen == OrigenIglesia.osm) i.idIglesia,
      for (final i in paquete.iglesias)
        if (_store.osmDescartadas.contains(
            DescarteOsm.idDocumento(fuente.denominacion, i.idDocumento)))
          i.idDocumento,
    };
    final nuevas = _planificador.faltantes(
      fuente: fuente,
      paquete: paquete,
      idsExistentes: existentes,
      creadoPor: miRef,
    );
    final yaExistian = total - nuevas.length;
    var hechas = yaExistian;
    alProgresar?.call(hechas, total);
    for (final lote in _planificador.enLotes(nuevas)) {
      await _store.esperar();
      _store.iglesias.add([..._store.iglesias.value, ...lote]);
      hechas += lote.length;
      alProgresar?.call(hechas, total);
    }
    return ResultadoImportacion(
      total: total,
      creadas: nuevas.length,
      yaExistian: yaExistian,
      atribucion: paquete.atribucion,
      porVerificar: nuevas.where((i) => i.porVerificar).length,
    );
  }
}
