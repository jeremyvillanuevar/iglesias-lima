import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/user_model.dart';

/// CRUD de la colección `users`. El id del documento es el uid de Firebase Auth.
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.users);

  DocumentReference<Map<String, dynamic>> refDe(String uid) => _col.doc(uid);

  Future<UserModel?> obtener(String uid) async {
    final snap = await _col.doc(uid).get();
    return snap.exists ? UserModel.fromFirestore(snap) : null;
  }

  Stream<UserModel?> observar(String uid) {
    return _col
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? UserModel.fromFirestore(snap) : null);
  }

  Future<void> crear(UserModel usuario) {
    return _col.doc(usuario.uid).set(usuario.toFirestore());
  }

  /// Crea el perfil la primera vez que alguien inicia sesión (Google o correo).
  Future<UserModel> crearSiNoExiste({
    required String uid,
    required String email,
    required String nombreCompleto,
  }) async {
    final existente = await obtener(uid);
    if (existente != null) return existente;

    final nuevo = UserModel.nuevo(
      uid: uid,
      email: email,
      nombreCompleto: nombreCompleto,
    );
    await crear(nuevo);
    return nuevo;
  }

  /// Las reglas solo permiten al usuario cambiar estos dos campos.
  Future<void> actualizarPerfil(
    String uid, {
    String? nombreCompleto,
    bool? perfilPublico,
  }) async {
    final cambios = <String, dynamic>{
      if (nombreCompleto != null) 'nombre_completo': nombreCompleto.trim(),
      if (perfilPublico != null) 'perfil_publico': perfilPublico,
    };
    if (cambios.isEmpty) return;
    await _col.doc(uid).update(cambios);
  }
}
