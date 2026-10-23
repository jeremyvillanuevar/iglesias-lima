import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;

import '../models/user_model.dart';

export '../services/auth_service.dart' show AuthCancelledException;
export 'auth_failure.dart';
export 'sesion_requerida_exception.dart';

/// Contrato de autenticación que usan los ViewModels.
///
/// Implementaciones:
/// * `FirebaseAuthRepository` (Firebase Auth + colección `users`).
/// * `DemoAuthRepository` (usuarios en memoria para el Modo Demo).
abstract class AuthRepository {
  /// Emite el uid del usuario cada vez que inicia o cierra sesión (null = sin sesión).
  Stream<String?> observarUid();

  bool get haySesion;

  /// Referencia al documento `users/{uid}` del usuario actual, o null.
  DocumentReference<Map<String, dynamic>>? get refUsuarioActual;

  /// Igual que [refUsuarioActual], pero lanza [SesionRequeridaException] si no hay sesión.
  DocumentReference<Map<String, dynamic>> requerirRefUsuario();

  /// Perfil del usuario actual en tiempo real (null si no hay sesión).
  Stream<UserModel?> observarPerfilActual();

  Future<UserModel> iniciarSesionConCorreo({
    required String email,
    required String password,
  });

  Future<UserModel> registrarConCorreo({
    required String nombreCompleto,
    required String email,
    required String password,
  });

  Future<UserModel> iniciarSesionConGoogle();

  Future<void> recuperarContrasena(String email);

  Future<void> cerrarSesion();

  Future<void> actualizarPerfil({String? nombreCompleto, bool? perfilPublico});
}
