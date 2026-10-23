import '../models/enums.dart';

/// Solo existe en el Modo Demo: permite "actuar como" otro rol
/// (Usuario, Pastor/Padre o Administrador General) para probar la
/// pantalla de Moderación sin tocar Firebase.
abstract interface class SelectorRolDemo {
  Future<void> cambiarRolDemo(RolGlobal rol);
}
