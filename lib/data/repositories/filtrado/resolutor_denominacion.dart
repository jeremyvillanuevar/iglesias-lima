import '../../models/enums.dart';
import '../../models/evento_model.dart';
import '../../models/iglesia_model.dart';
import '../../models/ministerio_model.dart';
import '../iglesia_repository.dart';
import '../ministerio_repository.dart';

/// Averigua la denominación de iglesias, ministerios y eventos, con una
/// caché en memoria (id de iglesia → denominación) para no repetir lecturas.
///
/// Lo usan los repositorios "PorDenominacion" de las Apps de una sola
/// denominación (Apps 1 a 4), que filtran del lado del cliente (SRS).
class ResolutorDenominacion {
  ResolutorDenominacion({
    required IglesiaRepository iglesias,
    required MinisterioRepository ministerios,
  })  : _iglesias = iglesias,
        _ministerios = ministerios;

  final IglesiaRepository _iglesias;
  final MinisterioRepository _ministerios;

  final Map<String, Denominacion> _porIglesia = {};
  final Map<String, Denominacion?> _porMinisterio = {};

  /// Guarda en la caché las iglesias ya leídas (p. ej. del mapa).
  void registrarIglesias(Iterable<IglesiaModel> iglesias) {
    for (final i in iglesias) {
      _porIglesia[i.idIglesia] = i.denominacion;
    }
  }

  Future<Denominacion?> deIglesia(String idIglesia) async {
    final enCache = _porIglesia[idIglesia];
    if (enCache != null) return enCache;
    final iglesia = await _iglesias.obtener(idIglesia);
    if (iglesia == null) return null;
    _porIglesia[idIglesia] = iglesia.denominacion;
    return iglesia.denominacion;
  }

  /// La propia del ministerio o, si no la tiene, la de su iglesia matriz.
  Future<Denominacion?> deMinisterio(MinisterioModel m) async {
    if (m.denominacion != null) return m.denominacion;
    final matriz = m.iglesiaRef;
    return matriz == null ? null : deIglesia(matriz.id);
  }

  Future<Denominacion?> deMinisterioPorId(String idMinisterio) async {
    if (_porMinisterio.containsKey(idMinisterio)) {
      return _porMinisterio[idMinisterio];
    }
    final m = await _ministerios.obtener(idMinisterio);
    final d = m == null ? null : await deMinisterio(m);
    _porMinisterio[idMinisterio] = d;
    return d;
  }

  /// La de su iglesia o, si es de un ministerio independiente, la del ministerio.
  Future<Denominacion?> deEvento(EventoModel e) async {
    final iglesia = e.iglesiaRef;
    if (iglesia != null) return deIglesia(iglesia.id);
    final ministerio = e.ministerioRef;
    if (ministerio != null) return deMinisterioPorId(ministerio.id);
    return null;
  }

  /// Deja solo los elementos cuya denominación es [denominacion]
  /// (los que no se pueden resolver se descartan).
  Future<List<T>> filtrar<T>(
    List<T> elementos,
    Denominacion denominacion,
    Future<Denominacion?> Function(T) resolver,
  ) async {
    final resultado = <T>[];
    for (final e in elementos) {
      if (await resolver(e) == denominacion) resultado.add(e);
    }
    return resultado;
  }
}
