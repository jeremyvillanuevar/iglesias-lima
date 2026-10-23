import '../../../core/config/fuente_importacion_osm.dart';
import '../../importacion/lector_importacion_osm.dart';
import '../../importacion/planificador_importacion.dart';
import '../../importacion/progreso_importacion.dart';
import '../../importacion/resultado_importacion.dart';
import '../../models/enums.dart';
import '../../services/iglesia_service.dart';
import '../auth_repository.dart';
import '../importacion_iglesias_repository.dart';
import '../permisos_moderacion.dart';

/// Importa en Firestore, con el SDK y la sesión del Admin General (no usa
/// tokens de la CLI ni la API REST). Las reglas solo dejan crear iglesias
/// "OSM" al Admin General y con el id 'osm_<tipo>_<id>'.
class FirebaseImportacionIglesiasRepository
    implements ImportacionIglesiasRepository {
  FirebaseImportacionIglesiasRepository({
    required IglesiaService iglesiaService,
    required AuthRepository authRepository,
    LectorImportacionOsm? lector,
    PlanificadorImportacion planificador = const PlanificadorImportacion(),
  })  : _iglesias = iglesiaService,
        _auth = authRepository,
        _lector = lector ?? LectorImportacionOsm(),
        _planificador = planificador;

  final IglesiaService _iglesias;
  final AuthRepository _auth;
  final LectorImportacionOsm _lector;
  final PlanificadorImportacion _planificador;

  @override
  Future<ResultadoImportacion> importarDesdeOsm(
    FuenteImportacionOsm fuente, {
    ProgresoImportacion? alProgresar,
  }) async {
    final miRef = _auth.requerirRefUsuario();
    final perfil = await _auth.observarPerfilActual().first;
    PermisosModeracion.exigirAdminPara(
        perfil, 'importar iglesias de OpenStreetMap');

    final paquete = await _lector.leer(fuente);
    final total = paquete.iglesias.length;
    // Ya importadas (de CUALQUIER denominación: un mismo elemento de OSM
    // nunca se pisa entre apps) + descartadas para esta denominación.
    final existentes = {
      ...await _iglesias.idsPorOrigen(OrigenIglesia.osm),
      ...await _iglesias.idsOsmDescartados(fuente.denominacion),
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
      await _iglesias.crearEnLote(lote);
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
