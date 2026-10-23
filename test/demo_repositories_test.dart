import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter_test/flutter_test.dart';
import 'package:iglesias_app/data/demo/demo_auth_repository.dart';
import 'package:iglesias_app/data/demo/demo_data_store.dart';
import 'package:iglesias_app/data/demo/demo_datos_semilla.dart';
import 'package:iglesias_app/data/demo/demo_evento_repository.dart';
import 'package:iglesias_app/data/demo/demo_iglesia_repository.dart';
import 'package:iglesias_app/data/models/enums.dart';
import 'package:iglesias_app/data/recurrencia/frecuencia_recurrencia.dart';
import 'package:iglesias_app/data/recurrencia/generador_recurrencia.dart';
import 'package:iglesias_app/data/recurrencia/hora_del_dia.dart';
import 'package:iglesias_app/data/recurrencia/regla_recurrencia.dart';
import 'package:iglesias_app/data/repositories/auth_repository.dart';
import 'package:iglesias_app/data/repositories/evento_repository.dart';

void main() {
  late DemoDataStore store;
  late DemoAuthRepository auth;
  late DemoIglesiaRepository iglesias;
  late DemoEventoRepository eventos;

  setUp(() {
    store = DemoDataStore(latenciaSimulada: Duration.zero);
    auth = DemoAuthRepository(store);
    iglesias = DemoIglesiaRepository(store, auth);
    eventos = DemoEventoRepository(store, auth);
  });

  tearDown(() => store.cerrar());

  test(
      'sin sesión (repos sin filtrar) se ven las 10 iglesias públicas y ninguna Pendiente',
      () async {
    final lista = await iglesias.observarIglesiasDelMapa().first;
    // 6 católicas + 1 evangélica + 1 Testigos de Jehová + 1 IJSUD.
    expect(lista, hasLength(10));
    expect(lista.where((i) => i.denominacion == Denominacion.catolica),
        hasLength(6));
    expect(lista.every((i) => i.esPublica), isTrue);
    expect(
        lista.map((i) => i.denominacion).toSet(), Denominacion.values.toSet());
  });

  test('hay eventos en los próximos 30 días y en el historial (máx. 16 meses)',
      () async {
    final proximos = await eventos
        .observarEventosDeIglesia(DemoDatosSemilla.idCatedral)
        .first;
    final ahora = DateTime.now();
    expect(proximos, isNotEmpty);
    expect(
      proximos.every((e) =>
          e.fechaHoraInicio.isAfter(ahora) &&
          e.fechaHoraInicio.isBefore(ahora.add(const Duration(days: 30)))),
      isTrue,
    );

    final historial =
        await eventos.obtenerHistorialDeIglesia(DemoDatosSemilla.idCatedral);
    expect(historial, isNotEmpty);
    expect(historial.every((e) => e.fechaHoraInicio.isBefore(ahora)), isTrue);

    final todos = await eventos.observarProximos30Dias().first;
    expect(todos.any((e) => e.esVirtual && e.linkVirtual != null), isTrue);
  });

  test('crear sin sesión lanza SesionRequeridaException', () {
    expect(
      () => iglesias.crearIglesia(
        nombre: 'X',
        denominacion: Denominacion.catolica,
        tipo: TipoUbicacion.fisica,
        ubicacion: const GeoPoint(-12.1, -77.0),
      ),
      throwsA(isA<SesionRequeridaException>()),
    );
  });

  test(
      'login demo: valida correo/contraseña y muestra los Pendientes de ejemplo',
      () async {
    await expectLater(
      auth.iniciarSesionConCorreo(email: 'no-es-correo', password: '123456'),
      throwsA(isA<AuthFailure>()),
    );
    await expectLater(
      auth.iniciarSesionConCorreo(email: 'jeremy@ejemplo.pe', password: '123'),
      throwsA(isA<AuthFailure>()),
    );

    final usuario = await auth.iniciarSesionConCorreo(
        email: 'jeremy@ejemplo.pe', password: '123456');
    expect(usuario.email, 'jeremy@ejemplo.pe');
    expect(auth.haySesion, isTrue);

    final mapa = await iglesias.observarIglesiasDelMapa().first;
    expect(mapa.any((i) => i.estadoAprobacion == EstadoAprobacion.pendiente),
        isTrue);

    final miraflores = await eventos
        .observarEventosDeIglesia(DemoDatosSemilla.idMiraflores)
        .first;
    expect(
        miraflores.any((e) => e.estadoAprobacion == EstadoAprobacion.pendiente),
        isTrue);

    // Misma cuenta con otra contraseña: rechazada.
    await auth.cerrarSesion();
    await expectLater(
      auth.iniciarSesionConCorreo(
          email: 'jeremy@ejemplo.pe', password: 'otra-clave'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test(
      'crear iglesia + eventos recurrentes: aparecen al instante como Pendientes',
      () async {
    await auth.iniciarSesionConGoogle();

    final id = await iglesias.crearIglesia(
      nombre: 'Parroquia de prueba',
      denominacion: Denominacion.catolica,
      tipo: TipoUbicacion.fisica,
      ubicacion: const GeoPoint(-12.12, -77.03),
    );
    final mapa = await iglesias.observarIglesiasDelMapa().first;
    final nueva = mapa.firstWhere((i) => i.idIglesia == id);
    expect(nueva.estadoAprobacion, EstadoAprobacion.pendiente);
    expect(nueva.oficialidad, Oficialidad.informada);

    final manana = DateTime.now().add(const Duration(days: 1));
    final resultado = const GeneradorRecurrencia().generar(ReglaRecurrencia(
      fechaInicio: manana,
      turnos: const [HoraDelDia(7, 0), HoraDelDia(19, 0)],
      frecuencia: FrecuenciaRecurrencia.semanal,
      repeticiones: 3,
    ));
    final ids = await eventos.crearEventos(
      DatosNuevoEvento(
        tipoActividad: TipoActividad.misa,
        titulo: 'Misa de prueba',
        categoria: 'General',
        idIglesia: id,
        duracion: const Duration(hours: 1),
      ),
      resultado.ocurrencias,
    );
    expect(ids, hasLength(6));

    final lista = await eventos.observarEventosDeIglesia(id).first;
    expect(lista, hasLength(6));
    expect(lista.every((e) => e.estadoAprobacion == EstadoAprobacion.pendiente),
        isTrue);
    expect(lista.every((e) => e.esRecurrente), isTrue);
    expect(lista.first.patronRecurrencia, 'Semanal_07:00');
    expect(lista.first.fechaHoraFin,
        lista.first.fechaHoraInicio.add(const Duration(hours: 1)));

    // Al cerrar sesión, los Pendientes dejan de verse (RF-4.5).
    await auth.cerrarSesion();
    final sinSesion = await eventos.observarEventosDeIglesia(id).first;
    expect(sinSesion, isEmpty);
  });

  test('evento virtual sin enlace es rechazado', () async {
    await auth.iniciarSesionConGoogle();
    expect(
      () => eventos.crearEventos(
        const DatosNuevoEvento(
          tipoActividad: TipoActividad.culto,
          titulo: 'Culto en línea',
          categoria: 'Oración',
          idIglesia: DemoDatosSemilla.idSanIsidro,
          esVirtual: true,
        ),
        const GeneradorRecurrencia()
            .generar(ReglaRecurrencia(
              fechaInicio: DateTime.now().add(const Duration(days: 2)),
              turnos: const [HoraDelDia(20, 0)],
            ))
            .ocurrencias,
      ),
      throwsArgumentError,
    );
  });
}
