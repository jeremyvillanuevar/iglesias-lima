import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String uid;
  final String email;
  final String nombreCompleto;
  final RolGlobal rolGlobal;
  final EstadoCuenta estadoCuenta;

  // Gamificación (App 6, Fase 2): en el MVP solo se guardan los valores iniciales
  final int puntosTotales;
  final int rachaActual;
  final List<String> insigniasDesbloqueadas;
  final bool perfilPublico; // false = "Modo Incógnito"

  final DateTime? creadoEn; // (agregado)

  const UserModel({
    required this.uid,
    required this.email,
    required this.nombreCompleto,
    required this.rolGlobal,
    required this.estadoCuenta,
    required this.puntosTotales,
    required this.rachaActual,
    required this.insigniasDesbloqueadas,
    required this.perfilPublico,
    this.creadoEn,
  });

  /// Usuario recién registrado (Google o correo)
  factory UserModel.nuevo({
    required String uid,
    required String email,
    required String nombreCompleto,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      nombreCompleto: nombreCompleto,
      rolGlobal: RolGlobal.usuario,
      estadoCuenta: EstadoCuenta.activo,
      puntosTotales: 0,
      rachaActual: 0,
      insigniasDesbloqueadas: const [],
      perfilPublico: true,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      email: d['email'] as String? ?? '',
      nombreCompleto: d['nombre_completo'] as String? ?? '',
      rolGlobal: RolGlobal.fromValue(d['rol_global']),
      estadoCuenta: EstadoCuenta.fromValue(d['estado_cuenta']),
      puntosTotales: (d['puntos_totales'] as num?)?.toInt() ?? 0,
      rachaActual: (d['racha_actual'] as num?)?.toInt() ?? 0,
      insigniasDesbloqueadas:
          List<String>.from(d['insignias_desbloqueadas'] ?? const []),
      perfilPublico: d['perfil_publico'] as bool? ?? true,
      creadoEn: (d['creado_en'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'nombre_completo': nombreCompleto,
        'rol_global': rolGlobal.value,
        'estado_cuenta': estadoCuenta.value,
        'puntos_totales': puntosTotales,
        'racha_actual': rachaActual,
        'insignias_desbloqueadas': insigniasDesbloqueadas,
        'perfil_publico': perfilPublico,
        'creado_en': creadoEn != null
            ? Timestamp.fromDate(creadoEn!)
            : FieldValue.serverTimestamp(),
      };

  bool get esAdminGeneral => rolGlobal == RolGlobal.adminGeneral;
}
