import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/di/dependencias.dart';
import 'package:iglesias_app/data/demo/demo_auth_repository.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/data/demo/demo_datos_semilla.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:iglesias_app/data/recurrencia/generador_recurrencia.dart';
import 'package:iglesias_app/data/recurrencia/hora_del_dia.dart';
import 'package:iglesias_app/data/recurrencia/regla_recurrencia.dart';
import 'package:iglesias_app/data/repositories/evento_repository.dart';
import 'package:iglesias_app/data/repositories/permiso_denegado_exception.dart';
import 'package:iglesias_app/ui/admin/moderacion_view_model.dart';

/// Moderación (Aprobar / Rechazar / Borrar) en el Modo Demo de la App 1.
void main() {
  late DemoDataStore store;
  late Dependencias deps;
  late DemoAuthRepository auth;

  setUp(() async {
    store = DemoDataStore(latenciaSimulada: Duration.zero);
    deps = Dependencias.demo(flavor: AppFlavor.catolica, store: store);
    auth = deps.auth as DemoAuthRepository;
    await auth.iniciarSesionConGoogle();
  });
  tearDown(() => store.cerrar());

  test('el demo entra como Administrador General y ve todos los Pendientes',
      () async {
    expect(store.usuarioActual.value!.rolGlobal, RolGlobal.adminGeneral);
    final iglesias = await deps.iglesias.observarPendientesDeModeracion().first;
    expect(iglesias.map((i) => i.idIglesia),
        contains(DemoDatosSemilla.idCapillaPendiente));
    // Filtrado por la app: nada que no sea católico.
    expect(
        iglesias.every((i) => i.denominacion == Denominacion.catolica), isTrue);
    final ministerios =
        await deps.ministerios.observarPendientesDeModeracion().first;
    expect(ministerios, isNotEmpty);
    final eventos = await deps.eventos.observarPendientesDeModeracion().first;
    expect(eventos, isNotEmpty);
  });

  test('Pastor/Padre: aprueba lo de su iglesia pero no lo propio ni borra',
      () async {
    await auth.cambiarRolDemo(RolGlobal.pastorPadre);

    // Ve la capilla de la que es líder (creada por otra persona) y la aprueba.
    final pendientes =
        await deps.iglesias.observarPendientesDeModeracion().first;
    expect(pendientes.map((i) => i.idIglesia),
        contains(DemoDatosSemilla.idCapillaPendiente));
    await deps.iglesias.aprobar(DemoDatosSemilla.idCapillaPendiente);
    final capilla =
        await deps.iglesias.obtener(DemoDatosSemilla.idCapillaPendiente);
    expect(capilla!.estadoAprobacion, EstadoAprobacion.aprobado);

    // Crea un evento en su propia parroquia: no puede autoaprobarlo.
    final ids = await deps.eventos.crearEventos(
      const DatosNuevoEvento(
        tipoActividad: TipoActividad.misa,
        titulo: 'Misa propia',
        categoria: 'General',
        idIglesia: DemoDatosSemilla.idCatedral,
      ),
      const GeneradorRecurrencia()
          .generar(ReglaRecurrencia(
            fechaInicio: DateTime.now().add(const Duration(days: 3)),
            turnos: const [HoraDelDia(9, 0)],
          ))
          .ocurrencias,
    );
    await expectLater(deps.eventos.aprobar(ids.single),
        throwsA(isA<PermisoDenegadoException>()));

    // El borrado definitivo es solo del Administrador General.
    await expectLater(
      deps.iglesias
          .eliminarDefinitivamente(DemoDatosSemilla.idCapillaPendiente),
      throwsA(isA<PermisoDenegadoException>()),
    );
  });

  test(
      'Usuario común: sin pantalla de moderación; no aprueba lo ajeno ni borra',
      () async {
    await auth.cambiarRolDemo(RolGlobal.usuario);
    expect(await deps.iglesias.observarPendientesDeModeracion().first, isEmpty);
    // Ministerio independiente (sin iglesia matriz): solo el Admin General.
    await expectLater(
        deps.ministerios.aprobar(DemoDatosSemilla.idMinOracionSurquillo),
        throwsA(isA<PermisoDenegadoException>()));
    await expectLater(deps.eventos.eliminarDefinitivamente('cualquiera'),
        throwsA(isA<PermisoDenegadoException>()));
  });

  test('Admin: Rechazado deja de verse en el mapa; borrar elimina', () async {
    await deps.iglesias.rechazar(DemoDatosSemilla.idCapillaPendiente);
    final capilla =
        await deps.iglesias.obtener(DemoDatosSemilla.idCapillaPendiente);
    expect(capilla!.estadoAprobacion, EstadoAprobacion.rechazado);
    final mapa = await deps.iglesias.observarIglesiasDelMapa().first;
    expect(mapa.any((i) => i.idIglesia == DemoDatosSemilla.idCapillaPendiente),
        isFalse);

    await deps.ministerios
        .eliminarDefinitivamente(DemoDatosSemilla.idMinPastoralJuvenil);
    expect(
        await deps.ministerios.obtener(DemoDatosSemilla.idMinPastoralJuvenil),
        isNull);
  });

  test('ModeracionViewModel: aprobar quita el ítem de la lista', () async {
    final vm = ModeracionViewModel(
      authRepository: deps.auth,
      iglesiaRepository: deps.iglesias,
      ministerioRepository: deps.ministerios,
      eventoRepository: deps.eventos,
      reclamoRepository: deps.reclamos,
      terminologia: AppFlavor.catolica.terminologia,
    );
    addTearDown(vm.dispose);
    await pumpEventQueue();
    expect(vm.puedeModerar, isTrue);
    expect(vm.esAdmin, isTrue);
    expect(vm.iglesias.map((i) => i.idIglesia),
        contains(DemoDatosSemilla.idCapillaPendiente));

    final error = await vm.aprobarIglesia(DemoDatosSemilla.idCapillaPendiente);
    expect(error, isNull);
    await pumpEventQueue();
    expect(
        vm.iglesias
            .any((i) => i.idIglesia == DemoDatosSemilla.idCapillaPendiente),
        isFalse);
  });

  test('crear ministerio: Pendiente y el creador es su administrador',
      () async {
    final id = await deps.ministerios.crearMinisterio(
      nombre: 'Catequesis familiar',
      tipoUbicacion: TipoUbicacionMinisterio.iglesia,
      idIglesia: DemoDatosSemilla.idBarranco,
    );
    final m = await deps.ministerios.obtener(id);
    expect(m!.estadoAprobacion, EstadoAprobacion.pendiente);
    expect(m.coordinadorRef.path, auth.refUsuarioActual!.path);
    expect(m.denominacion, Denominacion.catolica);

    expect(
      () => deps.ministerios.crearMinisterio(
        nombre: 'Sin lugar',
        tipoUbicacion: TipoUbicacionMinisterio.fisica,
      ),
      throwsArgumentError,
    );
  });
}
