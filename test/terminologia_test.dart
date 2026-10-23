import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/config/terminologia.dart';
import 'package:iglesias_app/data/models/enums.dart';

void main() {
  test('App 1 Católica: Usuario / Laicado, Padre y solo Misa (sin Culto)', () {
    final t = AppFlavor.catolica.terminologia;
    expect(t, same(Terminologia.catolica));
    expect(t.etiquetaRol(RolGlobal.usuario), 'Usuario / Laicado');
    expect(t.etiquetaRol(RolGlobal.pastorPadre), 'Padre');
    expect(t.etiquetaCampoLider, 'Padre');
    expect(t.tiposActividad, [TipoActividad.misa, TipoActividad.reunion]);
    expect(t.tiposActividad, isNot(contains(TipoActividad.culto)));
    expect(t.resumenTiposActividad, 'Misa o reunión');
  });

  test('App 2 Evangélica: Culto, Pastor y Usuario / Congregación', () {
    final t = AppFlavor.evangelica.terminologia;
    expect(t.etiquetaRol(RolGlobal.usuario), 'Usuario / Congregación');
    expect(t.etiquetaRol(RolGlobal.pastorPadre), 'Pastor');
    expect(t.etiquetaCampoLider, 'Pastor');
    expect(t.tiposActividad, [TipoActividad.culto, TipoActividad.reunion]);
    expect(t.resumenTiposActividad, 'Culto o reunión');
  });

  test('Apps 3, 4 y 5 conservan los textos generales', () {
    for (final f in [AppFlavor.jehova, AppFlavor.ijsud, AppFlavor.global]) {
      final t = f.terminologia;
      expect(t, same(Terminologia.general));
      expect(t.etiquetaRol(RolGlobal.usuario), 'Usuario / Congregación');
      expect(t.etiquetaCampoLider, 'Pastor / Padre a cargo');
      expect(t.tiposActividad, TipoActividad.values);
      expect(t.resumenTiposActividad, 'Misa, culto o reunión');
    }
  });

  test('los valores guardados en Firestore no cambian', () {
    expect(RolGlobal.usuario.value, 'Usuario');
    expect(RolGlobal.pastorPadre.value, 'Pastor_Padre');
    expect(TipoActividad.misa.value, 'Misa');
    expect(TipoActividad.culto.value, 'Culto');
    expect(Terminologia.catolica.etiquetaRol(RolGlobal.adminGeneral),
        RolGlobal.adminGeneral.label);
  });
}
