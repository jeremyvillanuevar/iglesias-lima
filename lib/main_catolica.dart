import 'core/config/app_flavor.dart';
import 'core/di/arranque_app.dart';

/// App 1: Católica.
///
/// flutter run --flavor catolica -t lib/main_catolica.dart
Future<void> main() => arrancarApp(AppFlavor.catolica);
