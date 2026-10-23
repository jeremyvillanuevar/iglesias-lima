# Cómo conectar Firebase y Google Maps — Ecosistema "Iglesias Lima"

Esta guía explica cómo está conectada la **App 1 (Católica)** al proyecto real de
Firebase **`iglesias-lima`**, qué falta hacer en la consola (reglas, primer
administrador) y cómo activar **Google Maps** y las demás apps más adelante.

## Las apps del ecosistema

Un solo código Flutter genera **5 apps** (flavors). Todas usan **el mismo
proyecto de Firebase** (`iglesias-lima`): las mismas cuentas, la misma base de
datos y las mismas reglas.

| App | Flavor (`--flavor`) | Punto de entrada | Paquete Android (applicationId) | Nombre visible | Firebase hoy |
|---|---|---|---|---|---|
| **App 1** | `catolica` | `lib/main_catolica.dart` | `pe.iglesiaslima.catolica` | Iglesias Católicas Lima | **Conectada** (Android y web) |
| **App 2** | `evangelica` | `lib/main_evangelica.dart` | `pe.iglesiaslima.evangelica` | Iglesias Evangélicas Lima | **Conectada** (Android; App ID `1:229289277006:android:21d73df3ca75b30727751f`) |
| App 7 (planificada) | — | — | — | Adventista | Solo datos (asset); sin Firebase app aún |
| App 3 | `jehova` | `lib/main_jehova.dart` | `pe.iglesiaslima.testigos` | Testigos de Jehová Lima | Modo Demo (sin registrar) |
| App 4 | `ijsud` | `lib/main_ijsud.dart` | `pe.iglesiaslima.ijsud` | IJSUD Lima | Modo Demo (sin registrar) |
| App 5 | `global` | `lib/main_global.dart` | `pe.iglesiaslima.global` | Visión Global Cristiana | Modo Demo (sin registrar) |
| App 6 | — | (proyecto aparte, aún no programado) | — | Gamificación | — |

Datos del proyecto: ID `iglesias-lima`, número `229289277006`, Firestore
`(default)` en `southamerica-west1`, plan Spark (sin Cloud Functions).

---

## 0. Cómo decide la app entre Firebase y Modo Demo

Al arrancar, cada app revisa **solo sus propios valores** en
`lib/firebase_options.dart`:

| Situación | Qué hace la app |
|---|---|
| Los valores de esa app son reales (hoy: **App 1**) | Se conecta a **Firebase real**. No aparece el chip amarillo. |
| Su App ID todavía dice `PEGA_AQUI_...` (hoy: Apps 2 a 5) | Arranca en **Modo Demo** (datos de ejemplo en memoria). |
| Firebase falla al iniciar (sin internet al abrir, datos mal pegados) | También arranca en **Modo Demo**; al tocar el chip se ve el motivo. |
| Hay clave de Google Maps (hoy, App 1) | Usa **Google Maps**; si falla al cargar, cambia solo a **OpenStreetMap**. |
| La clave de Maps es `PEGA_AQUI` | Usa **OpenStreetMap** (no necesita clave). |

No hay que tocar nada para apagar el Modo Demo de la App 1: ya está apagado.

---

## 1. Instalar el APK en tu Android

1. Copia `App1-Catolica-firebase-arm64.apk` a tu teléfono (WhatsApp a ti mismo, Google Drive, cable USB…).
2. Ábrelo y permite **"Instalar apps desconocidas"** para la app con la que lo abriste.
3. Si aparece **Play Protect** ("App no verificada"), toca *Más detalles → Instalar de todos modos*.
4. Requisitos: Android 7.0 o superior, teléfono de 64 bits (arm64).
5. Si tenías instalado el APK demo (`App1-Catolica-demo-arm64.apk`), se actualiza
   encima: es el mismo paquete y la misma firma.

> El APK de "release" está firmado con la **clave de depuración del proyecto**
> (`android/app/debug.keystore`, contraseña `android`), cuya SHA-1
> `67:5D:EE:09:07:4D:07:82:77:25:95:FC:37:77:12:9D:5B:60:12:A0` ya está
> registrada en Firebase. Para Google Play necesitas tu propia clave (sección 9).

---

## 2. Qué ya está configurado y qué falta en la consola

### 2.1 Ya hecho (en el código)
| Archivo | Qué contiene |
|---|---|
| `lib/firebase_options.dart` (líneas 26–29) | Proyecto: `iglesias-lima`, `229289277006`, bucket `iglesias-lima.firebasestorage.app`, authDomain `iglesias-lima.firebaseapp.com` |
| `lib/firebase_options.dart` (líneas 34–39) | API key Android y App ID Android de la App 1 (`1:229289277006:android:c263b9e76af88e5227751f`) |
| `lib/firebase_options.dart` (líneas 47–52) | API key web y App ID web de la App 1 (`1:229289277006:web:a0e127c754b453d927751f`) |
| `android/app/src/catolica/google-services.json` | Archivo descargado de Firebase para `pe.iglesiaslima.catolica` (incluye el cliente OAuth Android con la SHA-1 del proyecto) |
| `android/settings.gradle.kts` + `android/app/build.gradle.kts` | Plugin `com.google.gms.google-services` 4.5.0 aplicado. Lee el `google-services.json` **de cada flavor** (`android/app/src/<flavor>/`). Los flavors que aún no lo tienen compilan con un aviso (`missingGoogleServicesStrategy = WARN`) y arrancan en Modo Demo. |
| `lib/core/config/google_sign_in_config.dart` (línea 14) | ID de cliente web de Google `229289277006-u8vvk0ovkorn0l81416ud088m42db0si.apps.googleusercontent.com` (serverClientId en Android, clientId en web) |
| `web/index.html` (línea 27) | Meta `google-signin-client_id` con el mismo ID de cliente web |
| `firebase.json` + `.firebaserc` | Proyecto por defecto `iglesias-lima`; reglas `firestore.rules`, índices `firestore.indexes.json` |

### 2.2 Falta hacer en la consola de Firebase (una sola vez)
1. **Authentication → Método de acceso**: verifica que estén habilitados
   **Correo electrónico/contraseña** y **Google**.
2. **Authentication → Configuración → Dominios autorizados**: `localhost` e
   `iglesias-lima.firebaseapp.com` / `iglesias-lima.web.app` ya vienen. Agrega
   cualquier otro dominio donde publiques la web.
3. **Subir reglas e índices** (sección 6). Hasta entonces Firestore está en
   "denegar todo": la app abre, pero el mapa sale vacío y no se puede guardar nada
   (ni siquiera tu perfil de usuario).
4. **Nombrar al primer Administrador General** (sección 7.1).

---

## 3. Activar las Apps 2 a 5 (más adelante)

Por cada app (ej. `evangelica`, paquete `pe.iglesiaslima.evangelica`):
1. Firebase → ⚙️ Configuración del proyecto → **Agregar app → Android** con el
   paquete exacto de la tabla y la SHA-1 de arriba.
2. Descarga su `google-services.json` y guárdalo en
   `android/app/src/<flavor>/google-services.json` (ej. `android/app/src/evangelica/`).
3. En `lib/firebase_options.dart`, reemplaza su `PEGA_AQUI_TU_APP_ID_ANDROID_...`
   (líneas 40–43) por su `mobilesdk_app_id`. Para la web, su `PEGA_AQUI_TU_APP_ID_WEB_...`
   (líneas 53–56); puedes repetir el App ID web de la App 1.
4. En cuanto su App ID es real, esa app deja el Modo Demo sola.

- **No uses `flutterfire configure`**: reescribe `firebase_options.dart` con una
  sola app y se pierde la configuración por flavor.

---

## 4. Google Maps (activo en la App 1; OpenStreetMap como respaldo)

La App 1 ya trae una clave de Google Maps (proyecto de Google Cloud
`proyecto-agentes-457403`, con **Maps SDK for Android** y **Maps JavaScript API**
habilitadas y facturación activa). Por eso el mapa es **Google Maps** por defecto.

La clave está aislada en **un lugar por plataforma** (más el interruptor de Dart):

| Archivo | Línea | Para qué |
|---|---|---|
| `android/gradle.properties` | **18** | `GOOGLE_MAPS_API_KEY=...` → `android/app/build.gradle.kts` la inyecta en el AndroidManifest (`com.google.android.geo.API_KEY`). También se puede pasar al compilar: `-P GOOGLE_MAPS_API_KEY=otra_clave`. |
| `web/index.html` | **48** | `var claveGoogleMaps = "...";` → carga Maps JavaScript API. |
| `lib/core/config/maps_config.dart` | **26** | `defaultValue: '...'` → **interruptor**: si contiene `PEGA_AQUI`, la app dibuja OpenStreetMap en Android y web. También: `--dart-define=GOOGLE_MAPS_API_KEY=...`. |

**Respaldo automático a OpenStreetMap** (sin tocar nada):
- Clave con `PEGA_AQUI` en `maps_config.dart` → OpenStreetMap siempre.
- Web: mientras el script de Google carga se ve OpenStreetMap; si el script no
  carga en 12 s, falla, o Google rechaza la clave (`gm_authFailure`: clave
  restringida, sin facturación), la app cambia sola a OpenStreetMap.
- Android: si el mapa de Google no llega a crearse en 15 s (p. ej. teléfono sin
  Google Play Services), cambia a OpenStreetMap. Ojo: si Google rechaza la clave
  en Android, el SDK nativo no avisa a la app y el mapa sale gris; revisa
  `adb logcat | grep -i "maps\|API key"`.

**Cambiar a claves separadas y restringidas (recomendado antes de publicar)**:
1. En Google Cloud → APIs y servicios → Credenciales, crea dos claves:
   - *Android*: restringida a **Aplicaciones Android** → paquete
     `pe.iglesiaslima.catolica` + SHA-1 `67:5D:EE:…:12:A0` (y luego las demás
     apps), API **Maps SDK for Android**.
   - *Navegador*: restringida a **Sitios web** (`http://localhost/*`,
     `https://iglesias-lima.web.app/*`, `https://iglesias-lima.firebaseapp.com/*`
     y tu dominio), API **Maps JavaScript API**.
2. Pega la de Android en `android/gradle.properties` (línea 18) y la del navegador
   en `web/index.html` (línea 48). En `maps_config.dart` basta con que no diga
   `PEGA_AQUI` (puedes dejar cualquiera de las dos).
3. Vuelve a compilar el APK y la web.

---

## 5. Login con Google

- **Android**: Google acepta el login porque el paquete `pe.iglesiaslima.catolica`
  con la SHA-1 `67:5D:EE:…:12:A0` tiene su cliente OAuth Android
  (`229289277006-5tfqqn1a60ied1j7g2cqmvgmmbmfkt9o…`) y la app envía el ID de cliente
  web como `serverClientId`. Comprobar la SHA-1:
  ```bash
  keytool -list -v -keystore android/app/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```
  Si algún día firmas con otra clave (p. ej. la de Google Play), agrega esa SHA-1
  en Firebase y vuelve a descargar `google-services.json`.
- **Web (PWA)**: usa la ventana emergente de Firebase Auth. Solo necesita que el
  dominio esté en *Dominios autorizados*.

---

## 6. Subir las reglas e índices de Firestore

Ya están listos `firestore.rules`, `firestore.indexes.json`, `firebase.json` y
`.firebaserc` (proyecto `iglesias-lima`). Desde la carpeta del proyecto:

```bash
npm install -g firebase-tools        # o usa: npx firebase-tools ...
firebase login                       # abre el navegador; entra con la cuenta dueña del proyecto
firebase deploy --only firestore:rules,firestore:indexes --project iglesias-lima
```

Los índices tardan unos minutos en quedar "Habilitados" (Consola → Firestore →
Índices). Mientras tanto algunas listas pueden salir vacías.

Qué protegen las reglas:
- **Lectura pública** solo de lo `Aprobado` y `Activo`. Lo `Pendiente` o `Rechazado`
  solo lo ven su creador, su aprobador (líder) y el Administrador General.
- **Perfiles (`users`)**: cada persona crea **solo su propio** documento y siempre con
  `rol_global = 'Usuario'`; después solo puede cambiar `nombre_completo` y
  `perfil_publico`. **Nadie puede auto-ascenderse**: los roles solo los cambia un
  Administrador General o la consola de Firebase.
- **Moderación**: el Pastor/Padre líder de la iglesia (o de la iglesia matriz del
  ministerio) puede pasar `estado_aprobacion` a `Aprobado` o `Rechazado`, **excepto
  en lo que él mismo creó**. El Administrador General puede moderar todo.
- **Borrado definitivo**: solo el Administrador General.
- **Iglesias de OpenStreetMap**: solo el Administrador General las crea, con id
  `osm_<tipo>_<id>`, `origen = 'OSM'`, Aprobadas y `Sin_Administrador`. Nadie más
  puede escribir `origen`, `osm_id`, `estado_administracion` ni
  `verificacion_denominacion` (salvo el paso a `Reclamacion_Pendiente` al reclamar).
- **`solicitudes_reclamo`**: cada usuario crea solo la suya
  (`<idIglesia>_<uid>`, Pendiente, con cargo) sobre una iglesia pública sin
  líder y puede reenviarla si fue rechazada. Solo el Administrador General
  las lista, aprueba, rechaza o borra. Índice: `estado` + `creado_en`.
- **`osm_descartadas`**: solo el Administrador General.
- Denominaciones válidas: `Catolica`, `Evangelica`, `TestigosJehova`, `SantosUltimosDias`.
- `checkins` está cerrada: es de la **App 6 (Gamificación)**.

---

## 7. Roles y moderación

### 7.1 Primer Administrador General (una sola vez, desde la consola)
Las reglas no permiten que alguien se dé a sí mismo el rol de administrador desde
la app, así que el primero se nombra a mano en la consola (la consola tiene
permisos de dueño y no pasa por las reglas):

1. **Primero sube las reglas** (sección 6); con las reglas por defecto
   ("denegar todo") la app no puede crear tu perfil.
2. Abre la App 1 e **inicia sesión una vez** (correo o Google). La app crea tu
   documento `users/<tu UID>` con `rol_global: "Usuario"` y `estado_cuenta: "Activo"`.
3. Consola de Firebase → **Firestore Database → Datos → colección `users`**
   (en minúsculas). Abre el documento cuyo ID es tu UID (lo ves en
   Authentication → Usuarios → "UID de usuario"; el campo `email` también es el tuyo).
4. En el campo **`rol_global`** (tipo *string*), pulsa el lápiz y cambia
   `Usuario` por **`Admin_General`** (exacto: A y G mayúsculas, guion bajo). Guarda.
5. Verifica que **`estado_cuenta`** sea **`Activo`** (string). Las reglas solo
   reconocen al administrador si su cuenta está activa.
6. En la app, cierra sesión y vuelve a entrar. Ya verás **Moderación** en el menú
   de tu cuenta.

Valores válidos de `rol_global`: `Usuario`, `Coordinador`, `Pastor_Padre`,
`Admin_General`. Valores de `estado_cuenta`: `Activo`, `Suspendido`.
No cambies los demás campos (`uid`, `email`, `puntos_totales`, `racha_actual`,
`insignias_desbloqueadas`, `perfil_publico`, `creado_en`).

### 7.2 Nombrar a un Pastor/Padre aprobador
1. En su documento de `users`, cambia `rol_global` a **`Pastor_Padre`** (lo puede
   hacer el Administrador General desde la consola).
2. En el documento de su iglesia (colección `iglesias`), pon en `lider_uid_ref` una
   **referencia** (tipo *reference*) a `users/<UID del pastor>`.

### 7.3 Pantalla de Moderación (dentro de la app)
Está en **botón de cuenta (arriba a la derecha) → Moderación**. Solo la ven el
Administrador General y los Pastores/Padres. Tiene tres pestañas (Iglesias,
Ministerios y Eventos) con lo que está **Pendiente**:
- **Aprobar**: pasa a `Aprobado` y lo ve todo el mundo.
- **Rechazar**: pasa a `Rechazado`. Deja de aparecer en el mapa, pero no se borra.
- **Borrar** (solo el Administrador General): borrado definitivo.
- El Pastor/Padre ve lo de las iglesias donde es líder. Lo que él mismo creó
  aparece marcado y no puede aprobarlo: lo aprueba el Administrador General.
- Para marcar una iglesia como oficial, cambia `oficialidad` a `Verificada` en Firestore.

El Administrador General ve además:
- **Reclamos**: solicitudes "Reclamar / gestionar esta iglesia". *Aprobar* deja la
  iglesia `Administrada` con el solicitante como líder (pasa a Padre si era
  Usuario/Laicado o Coordinador); *Rechazar* la deja otra vez sin administrador.
- **Por verificar**: iglesias de OpenStreetMap sin etiqueta de denominación que
  entraron solo por su nombre (Parroquia, Capilla, San…). Se filtran por nombre;
  *Confirmar* las marca como católicas y *Descartar* las borra y evita que se
  vuelvan a importar.
- Botón **Importar iglesias de OpenStreetMap** (barra superior).

### 7.4 Importar iglesias de OpenStreetMap (una vez, desde la app)
1. Sube antes las reglas e índices (sección 6).
2. Entra como Administrador General → Moderación → icono de descarga
   **Importar iglesias de OpenStreetMap** → *Importar*.
3. Se muestra el progreso y al final cuántas se crearon, cuántas ya existían y
   cuántas quedan *por verificar*. Repetirlo es seguro: no duplica nada ni
   recrea las descartadas.
4. Los datos son © Colaboradores de OpenStreetMap (ODbL 1.0,
   https://www.openstreetmap.org/copyright); la atribución va en el archivo y en
   el diálogo. Para actualizar el archivo se vuelve a consultar Overpass y se
   regenera `assets/importacion/iglesias_catolicas_lima_osm.json`.

---

## 8. Compilar

Usa **JDK 17 o 21** y el Flutter del proyecto. La App 1 compila contra Firebase real.

```bash
flutter pub get

# App 1 (Católica): APK para teléfonos de 64 bits
flutter build apk --release --flavor catolica -t lib/main_catolica.dart --target-platform android-arm64
#   → build/app/outputs/flutter-apk/app-catolica-release.apk

# App 1 en el teléfono conectado
flutter run --flavor catolica -t lib/main_catolica.dart

# PWA web de la App 1 (en la web no hay flavors: el punto de entrada elige la app)
flutter build web --release -t lib/main_catolica.dart
#   → build/web

# Más adelante, las demás apps (mismo patrón):
flutter build apk --release --flavor global -t lib/main_global.dart
```

- Como el proyecto trae su propia clave de depuración, un APK compilado en tu PC
  **se instala encima** del que ya tienes (misma firma, misma SHA-1).
- Cada flavor tiene su propio paquete, así que en un teléfono pueden convivir las 5
  apps a la vez.

Si quieres publicar la web gratis en Firebase Hosting (opcional):
```bash
firebase init hosting    # carpeta pública: build/web ; app de una sola página: Sí
firebase deploy --only hosting
```

---

## 9. Antes de publicar en Google Play

1. Crea tu clave de subida:
   `keytool -genkey -v -keystore ~/iglesias-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. En `android/app/build.gradle.kts`, crea un `signingConfig` "release" con esa clave
   y úsalo en `buildTypes.release` (hoy usa `signingConfigs.getByName("debug")`).
   Guarda la clave y sus contraseñas fuera del repositorio.
3. Genera el bundle con
   `flutter build appbundle --release --flavor catolica -t lib/main_catolica.dart`
   y agrega la SHA-1 de Play a Firebase (sección 5).

---

## 10. Datos de ejemplo del Modo Demo

Son ilustrativos (los nombres dicen "(ejemplo)") y **no** son horarios oficiales.
La App 1 solo muestra los católicos. Los demás quedan en los datos de ejemplo
para las Apps 2 a 5.

| Iglesia | Denominación | Distrito | Estado |
|---|---|---|---|
| Catedral Basílica de Lima (ejemplo) | Católica | Cercado de Lima | Aprobada |
| Parroquia Virgen Milagrosa (ejemplo) | Católica | Miraflores | Aprobada |
| Parroquia San Pedro de Barranco (ejemplo) | Católica | Barranco | Aprobada |
| Parroquia Santa Rosa de Lince (ejemplo) | Católica | Lince | Aprobada |
| Parroquia Nuestra Señora del Carmen (ejemplo) | Católica | Santiago de Surco | Aprobada |
| Parroquia San Martín de Porres (ejemplo) | Católica | San Martín de Porres | Aprobada |
| Capilla San José Obrero (ejemplo) | Católica | Comas | **Pendiente** (propuesta por un fiel) |
| Iglesia Evangélica Pueblo de Dios (ejemplo) | Evangélica | San Isidro | Aprobada |
| Salón del Reino de los Testigos de Jehová (ejemplo) | Testigos de Jehová | San Juan de Lurigancho | Aprobada |
| Capilla de La Iglesia de Jesucristo de los Santos de los Últimos Días (ejemplo) | IJSUD | La Molina | Aprobada |
| Comunidad Virtual de Oración Lima (ejemplo) | Evangélica | (virtual) | Pendiente |

Ministerios católicos de ejemplo: "Coro Polifónico de la Catedral" y "Rosario
en Línea Lima" (aprobados), y "Pastoral Juvenil Virgen Milagrosa" y "Grupo de
Oración San Benito – Surquillo" (pendientes).

Cada parroquia tiene misas y actividades en los **próximos 30 días** y también en
el **historial**.

Al iniciar sesión en el Modo Demo:
- Quedas como **líder** de la Catedral y de la parroquia de Miraflores, y como
  aprobador de la capilla de Comas.
- Los Pendientes "de ejemplo" (p. ej. "Retiro de Matrimonios") pasan a ser
  **tuyos**: como Pastor/Padre no puedes aprobarlos tú mismo.
- Los Pendientes propuestos por "otro fiel" (la capilla de Comas, la "Vigilia de
  oración por las vocaciones", la "Charla prematrimonial" y los dos ministerios
  pendientes) sirven para probar **Aprobar / Rechazar** en Moderación.

---

## 11. Limitaciones conocidas

- Modo Demo (Apps 2 a 5 hoy): todo vive en memoria y **se reinicia al cerrar la app**.
- App 1 con Firebase: hasta subir las reglas (sección 6) Firestore niega todo y el mapa sale vacío.
- Los datos de ejemplo de la sección 10 son solo del Modo Demo; la base real empieza vacía.
- El login real con Google en Android requiere la SHA-1 en cada app Android y el
  ID de cliente web (ya configurados para la App 1).
- La clave de Google Maps actual no está restringida y es la misma en Android y
  web; conviene cambiarla por dos claves restringidas (sección 4).
- OpenStreetMap (respaldo) usa los servidores públicos de teselas: bien para
  pruebas, no para mucho tráfico.
- La recurrencia crea como máximo **60 eventos por vez** y nunca más allá de
  **16 meses**. Para más fechas, usa "Clonar Evento".
- Moderación con Firebase: el Pastor/Padre ve los pendientes de las iglesias donde
  figura como `lider_uid_ref`. Los eventos propuestos para un ministerio
  independiente los modera el Administrador General.
- La App 6 (Gamificación) no está incluida: solo está prevista en el modelo
  de datos (`checkins`, puntos, rachas e insignias).
