import 'core/config/app_flavor.dart';
import 'core/di/arranque_app.dart';

/// App 2: Evangélica.
///
/// flutter run --flavor evangelica -t lib/main_evangelica.dart
Future<void> main() => arrancarApp(AppFlavor.evangelica);
