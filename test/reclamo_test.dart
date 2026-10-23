import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/core/config/app_flavor.dart';
import 'package:iglesias_app/core/constants/firestore_collections.dart';
import 'package:iglesias_app/core/di/dependencias.dart';
import 'package:iglesias_app/data/demo/demo_auth_repository.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/data/demo/demo_datos_semilla.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:iglesias_app/data/models/iglesia_model.dart';
import 'package:iglesias_app/data/models/solicitud_reclamo_model.dart';
import 'package:iglesias_app/data/repositories/permiso_denegado_exception.dart';
import 'package:iglesias_app/data/repositories/reglas_reclamo.dart';
import 'package:iglesias_app/ui/admin/moderacion_view_model.dart';
import 'package:iglesias_app/ui/reclamo/reclamar_iglesia_view_model.dart';

/// Reclamar / gestionar una iglesia sin administrador (Modo Demo, App 1).
void main() {
  late DemoDataStore store;
  late Dependencias deps;
  late DemoAuthRepository auth;

  const correoSolicitante = 'parroco.barranco@demo.pe';
  const clave = 'clave123';

  IglesiaModel iglesia(String id) =>
      store.iglesiaPorPath('${FirestoreCollections.iglesias}/$id')!;

  /// Entra como un usuario común (no admin) que pide la iglesia.
  Future<String> entrarComoSolicitante() async {
    final u = await auth.registrarConCorreo(
      nombreCompleto: 'Padre Juan Pérez',
      email: correoSolicitante,
      password: clave,
    );
    await auth.cambiarRolDemo(RolGlobal.usuario);
    return u.uid;
  }

  Future<void> entrarComoAdmin() async {
    await auth.cerrarSesion();
    await auth.iniciarSesionConGoogle();
    expect(store.usuarioActual.value!.rolGlobal, RolGlobal.adminGeneral);
  }

  setUp(() {
    store = DemoDataStore(latenciaSimulada: Duration.zero);
    deps = Dependencias.demo(flavor: AppFlavor.catolica, store: store);
    auth = deps.auth as DemoAuthRepository;
  });
  tearDown(() => store.cerrar());

  test('las iglesias sin líder vinculado se pueden reclamar', () {
    expect(iglesia(DemoDatosSemilla.idBarranco).admiteReclamo, isTrue);
    expect(iglesia(DemoDatosSemilla.idCatedral).admiteReclamo, isFalse);
    expect(iglesia(DemoDatosSemilla.idCatedral).estadoAdministracion,
        EstadoAdministracion.administrada);
  });

  test('reclamar crea la solicitud Pendiente; aprobar asigna el administrador',
      () async {
    final uid = await entrarComoSolicitante();
    await deps.reclamos.reclamar(
      iglesia: iglesia(DemoDatosSemilla.idBarranco),
      cargo: 'Párroco',
      mensaje: 'Teléfono de la parroquia: 01 000 0000',
    );

    final mia = await deps.reclamos
        .observarMiSolicitud(DemoDatosSemilla.idBarranco)
        .first;
    expect(mia, isNotNull);
    expect(mia!.estado, EstadoAprobacion.pendiente);
    expect(
        mia.idSolicitud,
        SolicitudReclamoModel.idPara(
            idIglesia: DemoDatosSemilla.idBarranco, uid: uid));
    // Todavía no la administra.
    final pendiente = iglesia(DemoDatosSemilla.idBarranco);
    expect(pendiente.estadoAdministracion,
        EstadoAdministracion.reclamacionPendiente);
    expect(pendiente.liderUidRef, isNull);

    // No puede enviar otra mientras está en revisión.
    expect(
      () => deps.reclamos.reclamar(iglesia: pendiente, cargo: 'Párroco'),
      throwsArgumentError,
    );
    // Un usuario común no ve ni aprueba reclamos.
    expect(await deps.reclamos.observarPendientes().first, isEmpty);
    expect(() => deps.reclamos.aprobar(mia.idSolicitud),
        throwsA(isA<PermisoDenegadoException>()));

    await entrarComoAdmin();
    final pendientes = await deps.reclamos.observarPendientes().first;
    expect(pendientes.map((s) => s.idSolicitud), [mia.idSolicitud]);
    await deps.reclamos.aprobar(mia.idSolicitud);

    final administrada = iglesia(DemoDatosSemilla.idBarranco);
    expect(
        administrada.estadoAdministracion, EstadoAdministracion.administrada);
    expect(administrada.liderUidRef!.path, 'users/$uid');
    expect(administrada.admiteReclamo, isFalse);
    expect(store.usuarioPorUid(uid)!.rolGlobal, RolGlobal.pastorPadre);
    expect(store.solicitudesReclamo.value.single.estado,
        EstadoAprobacion.aprobado);
    expect(await deps.reclamos.observarPendientes().first, isEmpty);
  });

  test('rechazar deja la iglesia otra vez "Sin administrador"', () async {
    await entrarComoSolicitante();
    await deps.reclamos.reclamar(
        iglesia: iglesia(DemoDatosSemilla.idLince), cargo: 'Secretario');
    await entrarComoAdmin();
    final id =
        (await deps.reclamos.observarPendientes().first).single.idSolicitud;
    await deps.reclamos.rechazar(id);

    expect(iglesia(DemoDatosSemilla.idLince).estadoAdministracion,
        EstadoAdministracion.sinAdministrador);
    expect(iglesia(DemoDatosSemilla.idLince).liderUidRef, isNull);
    expect(store.solicitudesReclamo.value.single.estado,
        EstadoAprobacion.rechazado);
    // Ya resuelta: no se puede aprobar después.
    expect(() => deps.reclamos.aprobar(id), throwsArgumentError);
  });

  test('no se reclaman iglesias administradas ni sin cargo', () async {
    await entrarComoSolicitante();
    expect(
      () => deps.reclamos.reclamar(
          iglesia: iglesia(DemoDatosSemilla.idCatedral), cargo: 'Párroco'),
      throwsArgumentError,
    );
    expect(
      () => deps.reclamos
          .reclamar(iglesia: iglesia(DemoDatosSemilla.idSurco), cargo: '  '),
      throwsArgumentError,
    );
    expect(store.solicitudesReclamo.value, isEmpty);
  });

  test('la App 1 no acepta reclamos de otra denominación', () async {
    await entrarComoSolicitante();
    expect(
      () => deps.reclamos.reclamar(
          iglesia: iglesia(DemoDatosSemilla.idSanIsidro), cargo: 'Pastor'),
      throwsArgumentError,
    );
  });

  test('rol tras aprobar: Usuario y Coordinador pasan a Pastor/Padre', () {
    expect(
        ReglasReclamo.rolTrasAprobar(RolGlobal.usuario), RolGlobal.pastorPadre);
    expect(ReglasReclamo.rolTrasAprobar(RolGlobal.coordinador),
        RolGlobal.pastorPadre);
    expect(ReglasReclamo.rolTrasAprobar(RolGlobal.adminGeneral),
        RolGlobal.adminGeneral);
  });

  test('ViewModels: el solicitante envía y el admin aprueba en Moderación',
      () async {
    await entrarComoSolicitante();
    final reclamar = ReclamarIglesiaViewModel(
      reclamoRepository: deps.reclamos,
      iglesia: iglesia(DemoDatosSemilla.idSmp),
    );
    addTearDown(reclamar.dispose);
    await pumpEventQueue();
    expect(reclamar.puedeEnviar, isTrue);
    expect(await reclamar.enviar(cargo: 'Párroco'), isTrue);
    await pumpEventQueue();
    expect(reclamar.puedeEnviar, isFalse);
    expect(reclamar.textoEstado, contains('en revisión'));

    await entrarComoAdmin();
    final moderacion = ModeracionViewModel(
      authRepository: deps.auth,
      iglesiaRepository: deps.iglesias,
      ministerioRepository: deps.ministerios,
      eventoRepository: deps.eventos,
      reclamoRepository: deps.reclamos,
      terminologia: AppFlavor.catolica.terminologia,
    );
    addTearDown(moderacion.dispose);
    await pumpEventQueue();
    expect(moderacion.muestraReclamos, isTrue);
    expect(moderacion.reclamos, hasLength(1));
    expect(
        await moderacion.aprobarReclamo(moderacion.reclamos.single.idSolicitud),
        isNull);
    await pumpEventQueue();
    expect(moderacion.reclamos, isEmpty);
    expect(iglesia(DemoDatosSemilla.idSmp).esAdministrada, isTrue);
  });
}
