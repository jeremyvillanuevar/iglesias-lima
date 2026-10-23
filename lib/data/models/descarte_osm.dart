import 'enums.dart';

/// Documento de `osm_descartadas`: una iglesia de OpenStreetMap que el
/// Administrador General descartó para UNA denominación (así descartarla en
/// una app no la esconde de la importación de otra).
///
/// Id: '<Denominacion>_<idIglesia>' (ej. 'Evangelica_osm_node_1'). Los
/// documentos anteriores, sin el campo `denominacion`, son católicos y usan
/// como id el de la iglesia.
abstract final class DescarteOsm {
  /// Id del documento para la iglesia [idIglesia] descartada en [d].
  static String idDocumento(Denominacion d, String idIglesia) =>
      '${d.value}_$idIglesia';

  /// Denominación del descarte (los antiguos, sin el campo, son católicos).
  static Denominacion denominacionDe(Map<String, dynamic> datos) =>
      datos['denominacion'] == null
          ? Denominacion.catolica
          : Denominacion.fromValue(datos['denominacion']);

  /// Id de la iglesia descartada (los antiguos lo tienen como id del doc).
  static String idIglesiaDe(String idDocumento, Map<String, dynamic> datos) =>
      datos['id_iglesia'] as String? ?? idDocumento;
}
