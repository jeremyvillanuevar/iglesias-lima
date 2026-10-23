import 'core/config/app_flavor.dart';
import 'core/di/arranque_app.dart';

/// App 3: Testigos de Jehová.
///
/// flutter run --flavor jehova -t lib/main_jehova.dart
Future<void> main() => arrancarApp(AppFlavor.jehova);
