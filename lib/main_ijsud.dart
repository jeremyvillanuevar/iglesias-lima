import 'core/config/app_flavor.dart';
import 'core/di/arranque_app.dart';

/// App 4: IJSUD (Iglesia de Jesucristo de los Santos de los Últimos Días).
///
/// flutter run --flavor ijsud -t lib/main_ijsud.dart
Future<void> main() => arrancarApp(AppFlavor.ijsud);
