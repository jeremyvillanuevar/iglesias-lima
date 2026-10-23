import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/terminologia.dart';
import '../../data/models/user_model.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/permisos_moderacion.dart';
import '../../data/repositories/selector_rol_demo.dart';

/// Estado de la sesión para toda la app (login con Google o correo, RF-1.1).
/// Se puede navegar el mapa sin sesión; para crear se pide iniciar sesión.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required AuthRepository authRepository,
    required this.modoDemo,
    required this.terminologia,
  }) : _repo = authRepository {
    _sub = _repo.observarPerfilActual().listen(
      (perfil) {
        _perfil = perfil;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'No se pudo cargar tu perfil: $e';
        notifyListeners();
      },
    );
  }

  final AuthRepository _repo;
  final bool modoDemo;

  /// Vocabulario de la app (nombres visibles de los roles).
  final Terminologia terminologia;
  StreamSubscription<UserModel?>? _sub;

  UserModel? _perfil;
  bool _cargando = false;
  String? _error;

  UserModel? get perfil => _perfil;
  bool get haySesion => _repo.haySesion;
  bool get cargando => _cargando;
  String? get error => _error;

  String get nombreVisible {
    final p = _perfil;
    if (p == null) return '';
    return p.nombreCompleto.isNotEmpty ? p.nombreCompleto : p.email;
  }

  /// Nombre visible de [rol] en esta app (ej. 'Usuario / Laicado').
  String etiquetaRol(RolGlobal rol) => terminologia.etiquetaRol(rol);

  /// Admin General o Pastor/Padre: ve la entrada "Moderación".
  bool get puedeModerar => PermisosModeracion.puedeAbrirModeracion(_perfil);
  bool get esAdmin => PermisosModeracion.esAdmin(_perfil);

  /// Solo en el Modo Demo se puede "actuar como" otro rol.
  bool get puedeCambiarRolDemo =>
      modoDemo && _repo is SelectorRolDemo && haySesion;

  /// Roles disponibles en el selector del Modo Demo.
  static const List<RolGlobal> rolesDemo = [
    RolGlobal.usuario,
    RolGlobal.pastorPadre,
    RolGlobal.adminGeneral,
  ];

  Future<void> cambiarRolDemo(RolGlobal rol) async {
    final repo = _repo;
    if (!modoDemo || repo is! SelectorRolDemo) return;
    await (repo as SelectorRolDemo).cambiarRolDemo(rol);
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> iniciarSesionConCorreo(String email, String password) =>
      _ejecutar(
          () => _repo.iniciarSesionConCorreo(email: email, password: password));

  Future<bool> registrar({
    required String nombre,
    required String email,
    required String password,
  }) =>
      _ejecutar(() => _repo.registrarConCorreo(
            nombreCompleto: nombre,
            email: email,
            password: password,
          ));

  Future<bool> iniciarSesionConGoogle() =>
      _ejecutar(_repo.iniciarSesionConGoogle);

  /// Envía el correo para restablecer la contraseña.
  Future<bool> recuperarContrasena(String email) =>
      _ejecutar(() => _repo.recuperarContrasena(email));

  Future<void> cerrarSesion() async {
    await _repo.cerrarSesion();
    _perfil = null;
    notifyListeners();
  }

  Future<bool> _ejecutar(Future<Object?> Function() accion) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } on AuthCancelledException {
      return false; // el usuario cerró la ventana de Google: no es un error
    } on AuthFailure catch (e) {
      _error = e.mensaje;
      return false;
    } catch (e) {
      _error = 'Ocurrió un error inesperado. Inténtalo de nuevo.\n($e)';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
