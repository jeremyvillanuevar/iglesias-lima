import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// El usuario cerró la ventana de Google sin elegir cuenta.
class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'Inicio de sesión cancelado.';
}

/// Única clase que habla con Firebase Authentication (RF-1.1).
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ---------- Correo y contraseña ----------
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String nombreCompleto,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(nombreCompleto.trim());
    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ---------- Google ----------
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // PWA: Firebase abre el popup de Google directamente.
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      try {
        return await _auth.signInWithPopup(provider);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          throw const AuthCancelledException();
        }
        rethrow;
      }
    }

    // Android nativo
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw const AuthCancelledException();

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ---------- Cerrar sesión ----------
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Si no había sesión de Google, no pasa nada.
      }
    }
    await _auth.signOut();
  }
}
