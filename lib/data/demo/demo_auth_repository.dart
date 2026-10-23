import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;

import '../../core/constants/firestore_collections.dart';
import '../../core/utils/validators.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/selector_rol_demo.dart';
import 'demo_data_store.dart';

/// Inicio de sesión SIMULADO del Modo Demo: cualquier correo válido con una
/// contraseña de 6 o más caracteres crea un usuario en memoria.
///
/// Para poder probar la Moderación, el usuario simulado entra como
/// Administrador General y puede cambiar de rol (Usuario / Pastor-Padre /
/// Admin General) desde el menú de su cuenta ([SelectorRolDemo]).
/// Además pasa a ser el líder (Pastor/Padre) de las iglesias de ejemplo que
/// tienen líder vinculado.
class DemoAuthRepository implements AuthRepository, SelectorRolDemo {
  DemoAuthRepository(this._store);

  final DemoDataStore _store;

  static const String correoGoogleDemo = 'usuario.demo@gmail.com';

  /// Rol con el que entra un usuario nuevo en el Modo Demo.
  static const RolGlobal rolInicialDemo = RolGlobal.adminGeneral;

  @override
  Stream<String?> observarUid() =>
      _store.usuarioActual.map((u) => u?.uid).distinct();

  @override
  bool get haySesion => _store.usuarioActual.value != null;

  @override
  DocumentReference<Map<String, dynamic>>? get refUsuarioActual {
    final u = _store.usuarioActual.value;
    return u == null ? null : _store.ref(FirestoreCollections.users, u.uid);
  }

  @override
  DocumentReference<Map<String, dynamic>> requerirRefUsuario() {
    final ref = refUsuarioActual;
    if (ref == null) throw const SesionRequeridaException();
    return ref;
  }

  @override
  Stream<UserModel?> observarPerfilActual() => _store.usuarioActual.stream;

  @override
  Future<UserModel> iniciarSesionConCorreo({
    required String email,
    required String password,
  }) async {
    await _store.esperar();
    final correo = _validarCredenciales(email, password);
    final existente = _store.usuariosPorCorreo[correo];
    if (existente != null && _store.contrasenasPorCorreo[correo] != password) {
      throw const AuthFailure('Correo o contraseña incorrectos.');
    }
    final usuario = existente ??
        _crearUsuario(correo, password, nombre: correo.split('@').first);
    return _entrar(usuario);
  }

  @override
  Future<UserModel> registrarConCorreo({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    await _store.esperar();
    final correo = _validarCredenciales(email, password);
    if (Validators.nombre(nombreCompleto) != null) {
      throw const AuthFailure('Ingresa tu nombre.');
    }
    if (_store.usuariosPorCorreo.containsKey(correo)) {
      throw const AuthFailure('Ya existe una cuenta con ese correo.');
    }
    return _entrar(
        _crearUsuario(correo, password, nombre: nombreCompleto.trim()));
  }

  @override
  Future<UserModel> iniciarSesionConGoogle() async {
    await _store.esperar();
    final usuario = _store.usuariosPorCorreo[correoGoogleDemo] ??
        _crearUsuario(correoGoogleDemo, null, nombre: 'Usuario Google (demo)');
    return _entrar(usuario);
  }

  @override
  Future<void> recuperarContrasena(String email) async {
    await _store.esperar();
    final error = Validators.correo(email);
    if (error != null) throw AuthFailure(error);
    // En el Modo Demo no se envía ningún correo real.
  }

  @override
  Future<void> cerrarSesion() async {
    _store.usuarioActual.add(null);
  }

  @override
  Future<void> actualizarPerfil(
      {String? nombreCompleto, bool? perfilPublico}) async {
    final u = _store.usuarioActual.value;
    if (u == null) throw const SesionRequeridaException();
    _guardar(_copiar(
      u,
      nombreCompleto: nombreCompleto?.trim(),
      perfilPublico: perfilPublico,
    ));
  }

  @override
  Future<void> cambiarRolDemo(RolGlobal rol) async {
    final u = _store.usuarioActual.value;
    if (u == null) throw const SesionRequeridaException();
    _guardar(_copiar(u, rolGlobal: rol));
  }

  void _guardar(UserModel actualizado) {
    _store.usuariosPorCorreo[actualizado.email] = actualizado;
    _store.usuarioActual.add(actualizado);
  }

  UserModel _copiar(
    UserModel u, {
    String? nombreCompleto,
    bool? perfilPublico,
    RolGlobal? rolGlobal,
  }) {
    return UserModel(
      uid: u.uid,
      email: u.email,
      nombreCompleto: nombreCompleto ?? u.nombreCompleto,
      rolGlobal: rolGlobal ?? u.rolGlobal,
      estadoCuenta: u.estadoCuenta,
      puntosTotales: u.puntosTotales,
      rachaActual: u.rachaActual,
      insigniasDesbloqueadas: u.insigniasDesbloqueadas,
      perfilPublico: perfilPublico ?? u.perfilPublico,
      creadoEn: u.creadoEn,
    );
  }

  // ---------- Internos ----------
  String _validarCredenciales(String email, String password) {
    final errorCorreo = Validators.correo(email);
    if (errorCorreo != null) throw AuthFailure(errorCorreo);
    final errorClave = Validators.contrasena(password);
    if (errorClave != null) throw AuthFailure(errorClave);
    return email.trim().toLowerCase();
  }

  UserModel _crearUsuario(String correo, String? password,
      {required String nombre}) {
    final uid = 'demo-${correo.replaceAll(RegExp(r'[^a-z0-9]'), '-')}';
    final usuario = UserModel(
      uid: uid,
      email: correo,
      nombreCompleto: nombre,
      rolGlobal: rolInicialDemo,
      estadoCuenta: EstadoCuenta.activo,
      puntosTotales: 0,
      rachaActual: 0,
      insigniasDesbloqueadas: const [],
      perfilPublico: true,
      creadoEn: DateTime.now(),
    );
    _store.usuariosPorCorreo[correo] = usuario;
    if (password != null) _store.contrasenasPorCorreo[correo] = password;
    return usuario;
  }

  UserModel _entrar(UserModel usuario) {
    final ref = _store.ref(FirestoreCollections.users, usuario.uid);
    _store.reasignarPendientesDeEjemploA(ref);
    _store.reasignarLiderazgoDeEjemploA(ref);
    _store.usuarioActual.add(usuario);
    return usuario;
  }
}
