# Iglesias Lima — Ecosistema de apps (Flutter + Firebase)

Directorio de iglesias, ministerios y eventos (misas, cultos y reuniones) de Lima, Perú.
Un solo código genera **5 apps** (flavors) que comparten **un único backend Firebase**:

| App | Flavor | Paquete | Estado |
|---|---|---|---|
| 1 · Iglesias Católicas Lima | `catolica` | `pe.iglesiaslima.catolica` | **Entregada** (APK + web) |
| 2 · Iglesias Evangélicas Lima | `evangelica` | `pe.iglesiaslima.evangelica` | **Entregada** |
| 7 · Adventista (planificada) | — | — | Solo datos (asset + enum); sin flavor aún |
| 3 · Testigos de Jehová Lima | `jehova` | `pe.iglesiaslima.testigos` | Declarada |
| 4 · IJSUD Lima | `ijsud` | `pe.iglesiaslima.ijsud` | Declarada |
| 5 · Visión Global Cristiana (todas, con filtros) | `global` | `pe.iglesiaslima.global` | Declarada |
| 6 · Gamificación | — | — | Solo prevista (no se programa aquí) |

Android y PWA (web). Arquitectura **MVVM**: Vista → ViewModel (ChangeNotifier +
Provider) → Repositorio (interfaz) → Servicio (Firebase). El detalle está en
**[ARQUITECTURA.md](ARQUITECTURA.md)**.

## Arranque rápido (App 1)

```bash
flutter pub get
flutter run --flavor catolica -t lib/main_catolica.dart     # Android
flutter run -d chrome -t lib/main_catolica.dart             # web
flutter test
flutter build apk --release --flavor catolica -t lib/main_catolica.dart --target-platform android-arm64
# App 2 (el pubspec lleva la versión de App 1; se pasan nombre y build explícitos):
flutter build apk --release --flavor evangelica -t lib/main_evangelica.dart \
  --build-name 0.1.2 --build-number 3 --target-platform android-arm64
flutter build web --release -t lib/main_catolica.dart
```

La **App 1 (Católica)** y la **App 2 (Evangélica)** ya están conectadas al proyecto
real de Firebase `iglesias-lima` (Android; App 1 también web) y arrancan sin Modo
Demo. Las Apps 3 a 5 siguen en **Modo Demo** hasta registrarlas. Adventista está
planificada (datos listos; sin flavor).
El mapa es Google Maps (clave ya configurada) con respaldo automático a OpenStreetMap. Antes de usar la
App 1 hay que subir las reglas de Firestore y nombrar al primer administrador:

```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes --project iglesias-lima
```

Todos los pasos están en
**[COMO_CONECTAR_FIREBASE_Y_MAPS.md](COMO_CONECTAR_FIREBASE_Y_MAPS.md)**.

## Estructura

```
lib/
  main.dart, main_<flavor>.dart   puntos de entrada (uno por app)
  app.dart, firebase_options.dart (único archivo con claves de Firebase)
  core/
    config/        app_flavor (las 5 apps), maps_config, google_sign_in_config
    constants/     colecciones de Firestore y constantes (Lima, 30 días, 16 meses…)
    di/            arranque, inicializador y Dependencias (Firebase o Demo + filtro por app)
    routing/       rutas con su ViewModel
    theme/         tema por app y colores por denominación/estado
    utils/         validaciones, fechas, búsqueda sin tildes, GPS
  data/
    models/        users, iglesias, ministerios, eventos (+ enums)
    services/      única capa que habla con Firebase
    repositories/  interfaces + firebase/ (real) + filtrado/ (decoradores por denominación)
                   + permisos de moderación
    demo/          implementación en memoria (Modo Demo) + datos de ejemplo
    recurrencia/   generador de eventos recurrentes (sin Cloud Functions)
  ui/
    shared/        mapa (OSM / Google detrás de un solo widget), márgenes del sistema, widgets
    auth/          login, registro y AuthViewModel
    home_map/      mapa, filtros, Bottom Sheet de eventos e historial
    iglesia_form/  formulario de iglesia
    ministerio_form/ formulario de ministerio (RF-3)
    evento_form/   formulario de evento (turnos, recurrencia, clonar)
    admin/         pantalla de Moderación (Aprobar / Rechazar / Borrar)
test/              recurrencia, repositorios demo, filtrado por app, moderación y pantallas
```

## Reglas e índices

`firestore.rules` y `firestore.indexes.json` se suben con
`firebase deploy --only firestore:rules,firestore:indexes --project iglesias-lima`.

## Distribuir un APK a testers (Firebase App Distribution)

`scripts/distribuir_apk.sh` sube un APK ya compilado con la sesión de
`firebase login` (sin tokens):

```bash
scripts/distribuir_apk.sh <flavor> <ruta_apk> "<notas>" [testers]

# Ejemplo (App 1):
flutter build apk --release --flavor catolica -t lib/main_catolica.dart --target-platform android-arm64
scripts/distribuir_apk.sh catolica build/app/outputs/flutter-apk/app-catolica-release.apk \
  "Etiquetas Laicado/Misa/Padre e iglesias de OpenStreetMap"
```

- `flavor`: `catolica` y `evangelica` (registradas). Las demás apps se activan
  agregando su App ID de Firebase en el `case` del script.
- `testers`: correos separados por coma (por defecto `jeremyvillanueva@gmail.com`).
- Opcional: `FIREBASE_BIN` (ruta del CLI) y `FIREBASE_PROJECT` (por defecto `iglesias-lima`).
- Los testers reciben un correo con el enlace de descarga; la versión aparece en
  Consola de Firebase → App Distribution.
