import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/enums.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../auth_repository.dart';

/// Une Firebase Auth (sesión) con la colección `users` (perfil y rol).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required AuthService authService,
    required UserService userService,
  })  : _auth = authService,
        _users = userService;

  final AuthService _auth;
  final UserService _users;

  // ---------- Estado de sesión ----------
  Stream<User?> get cambiosDeSesion => _auth.authStateChanges();

  User? get usuarioFirebase => _auth.currentUser;

  @override
  Stream<String?> observarUid() =>
      cambiosDeSesion.map((u) => u?.uid).distinct();

  @override
  bool get haySesion => _auth.currentUser != null;

  /// Referencia al documento `users/{uid}` del usuario actual, o null.
  @override
  DocumentReference<Map<String, dynamic>>? get refUsuarioActual {
    final user = _auth.currentUser;
    return user == null ? null : _users.refDe(user.uid);
  }

  /// Igual que [refUsuarioActual], pero lanza error si no hay sesión.
  @override
  DocumentReference<Map<String, dynamic>> requerirRefUsuario() {
    final ref = refUsuarioActual;
    if (ref == null) throw const SesionRequeridaException();
    return ref;
  }

  /// Perfil del usuario actual en tiempo real (null si no hay sesión).
  @override
  Stream<UserModel?> observarPerfilActual() {
    return cambiosDeSesion.switchMap((user) {
      if (user == null) return Stream<UserModel?>.value(null);
      return _users.observar(user.uid);
    });
  }

  // ---------- Acciones ----------
  @override
  Future<UserModel> iniciarSesionConCorreo({
    required String email,
    required String password,
  }) {
    return _ejecutar(() async {
      final cred =
          await _auth.signInWithEmail(email: email, password: password);
      return _asegurarPerfil(cred.user!);
    });
  }

  @override
  Future<UserModel> registrarConCorreo({
    required String nombreCompleto,
    required String email,
    required String password,
  }) {
    return _ejecutar(() async {
      final cred = await _auth.registerWithEmail(
        email: email,
        password: password,
        nombreCompleto: nombreCompleto,
      );
      return _asegurarPerfil(cred.user!, nombre: nombreCompleto);
    });
  }

  @override
  Future<UserModel> iniciarSesionConGoogle() {
    return _ejecutar(() async {
      final cred = await _auth.signInWithGoogle();
      return _asegurarPerfil(cred.user!);
    });
  }

  @override
  Future<void> recuperarContrasena(String email) {
    return _ejecutar(() => _auth.sendPasswordResetEmail(email));
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  @override
  Future<void> actualizarPerfil({String? nombreCompleto, bool? perfilPublico}) {
    final user = _auth.currentUser;
    if (user == null) throw const SesionRequeridaException();
    return _users.actualizarPerfil(
      user.uid,
      nombreCompleto: nombreCompleto,
      perfilPublico: perfilPublico,
    );
  }

  // ---------- Internos ----------
  /// Crea el documento en `users` si es la primera vez y bloquea cuentas suspendidas.
  Future<UserModel> _asegurarPerfil(User user, {String? nombre}) async {
    final perfil = await _users.crearSiNoExiste(
      uid: user.uid,
      email: user.email ?? '',
      nombreCompleto: (nombre?.trim().isNotEmpty ?? false)
          ? nombre!.trim()
          : (user.displayName ?? user.email?.split('@').first ?? 'Usuario'),
    );

    if (perfil.estadoCuenta == EstadoCuenta.suspendido) {
      await _auth.signOut();
      throw const AuthFailure(
          'Tu cuenta está suspendida. Contacta al administrador.');
    }
    return perfil;
  }

  Future<T> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthCancelledException {
      rethrow;
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mensajeDeError(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure('Error del servidor: ${e.message ?? e.code}');
    }
  }

  String _mensajeDeError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'account-exists-with-different-credential':
        return 'Ese correo ya está registrado con otro método de inicio de sesión.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento y vuelve a probar.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      case 'popup-blocked':
        return 'El navegador bloqueó la ventana de Google. Permite las ventanas emergentes.';
      default:
        return 'No se pudo iniciar sesión ($code).';
    }
  }
}
