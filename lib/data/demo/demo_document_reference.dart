// En el Modo Demo no existe Firebase, pero los modelos usan DocumentReference
// para enlazar documentos. Esta clase imita una referencia (solo id y ruta)
// para que los mismos modelos funcionen en memoria.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';

/// Referencia "falsa" a un documento, usada solo en memoria (Modo Demo).
/// Cualquier intento de leer o escribir en Firestore con ella lanza un error.
class DemoDocumentReference implements DocumentReference<Map<String, dynamic>> {
  DemoDocumentReference(this.path)
      : assert(path.split('/').length.isEven, 'La ruta debe ser coleccion/id');

  @override
  final String path;

  @override
  String get id => path.split('/').last;

  /// Nombre de la colección (ej. "iglesias").
  String get coleccion => path.split('/').first;

  static Never _noDisponible() =>
      throw UnsupportedError('No disponible en Modo Demo (sin Firebase).');

  @override
  FirebaseFirestore get firestore => _noDisponible();

  @override
  CollectionReference<Map<String, dynamic>> get parent => _noDisponible();

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _noDisponible();

  @override
  Future<void> delete() => _noDisponible();

  @override
  Future<void> update(Map<Object, Object?> data) => _noDisponible();

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      _noDisponible();

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _noDisponible();

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) =>
      _noDisponible();

  @override
  DocumentReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) =>
      _noDisponible();

  @override
  bool operator ==(Object other) =>
      other is DocumentReference && other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'DemoDocumentReference($path)';
}
