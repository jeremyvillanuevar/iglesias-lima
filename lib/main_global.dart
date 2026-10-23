import 'core/config/app_flavor.dart';
import 'core/di/arranque_app.dart';

/// App 5: Visión Global Cristiana (todas las denominaciones).
///
/// flutter run --flavor global -t lib/main_global.dart
Future<void> main() => arrancarApp(AppFlavor.global);
