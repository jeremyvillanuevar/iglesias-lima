import '../../core/config/fuente_importacion_osm.dart';
import '../importacion/progreso_importacion.dart';
import '../importacion/resultado_importacion.dart';

/// Importa iglesias de OpenStreetMap (archivo incluido en la app) con la
/// sesión del Administrador General. Es idempotente: cada iglesia usa el id
/// fijo 'osm_<tipo>_<id>' y las que ya existen no se vuelven a escribir.
///
/// Implementaciones: `FirebaseImportacionIglesiasRepository` y
/// `DemoImportacionIglesiasRepository`.
abstract class ImportacionIglesiasRepository {
  Future<ResultadoImportacion> importarDesdeOsm(
    FuenteImportacionOsm fuente, {
    ProgresoImportacion? alProgresar,
  });
}
