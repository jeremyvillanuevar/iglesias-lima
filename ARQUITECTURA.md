# Arquitectura — Ecosistema "Iglesias Lima"

## 1. Visión general

- **Un backend, varias apps.** Un único proyecto de Firebase (Auth + Firestore,
  plan Spark) atiende a todas las apps. Las cuentas, las colecciones y las reglas
  son las mismas.
- **Un código, cinco apps.** Las Apps 1 a 5 salen de este mismo proyecto Flutter
  como *flavors*. La App 6 (Gamificación) será un proyecto aparte que reutilice
  el mismo backend; aquí solo queda prevista (colección `checkins`, cerrada en
  las reglas, y campos de puntos/rachas/insignias en `users`).
- **Entrega actual:** **App 1 – Iglesias Católicas Lima**
  (`pe.iglesiaslima.catolica`) y **App 2 – Iglesias Evangélicas Lima**
  (`pe.iglesiaslima.evangelica`). Las Apps 3 a 5 están declaradas. Adventista
  está planificada (datos listos; sin flavor aún).

| App | Flavor | Denominación fija |
|---|---|---|
| 1 | `catolica` | Católica (`Catolica`) |
| 2 | `evangelica` | Evangélica (`Evangelica`) — **entregada** |
| 7 (planificada) | — | Adventista (`Adventista`) — solo datos |
| 3 | `jehova` | Testigos de Jehová (`TestigosJehova`) |
| 4 | `ijsud` | Iglesia de Jesucristo de los Santos de los Últimos Días (`SantosUltimosDias`, abreviado IJSUD) |
| 5 | `global` | Ninguna: muestra todas, con chips de filtro |

## 2. Capas (MVVM + Provider)

```
Vista (Widget) ──► ViewModel (ChangeNotifier) ──► Repositorio (interfaz)
                                                   ├─ firebase/  ──► Servicio ──► Firestore / Auth
                                                   ├─ demo/      ──► DemoDataStore (memoria)
                                                   └─ filtrado/  (decorador por denominación)
```

- **Vistas** (`lib/ui/**`): solo dibujan y llaman al ViewModel.
- **ViewModels**: estado de la pantalla y validaciones de interfaz. Solo conocen
  las **interfaces** de los repositorios.
- **Repositorios** (`lib/data/repositories/*.dart`): contratos abstractos
  (`IglesiaRepository`, `MinisterioRepository`, `EventoRepository`,
  `AuthRepository`).
  - `firebase/`: la implementación real, que delega en los **servicios**
    (`lib/data/services`), única capa que importa Firestore/Auth.
  - `demo/`: la implementación en memoria con las **mismas reglas de negocio**
    (permisos, Pendiente/Rechazado, validaciones).
- **Reglas compartidas**: `ReglasValidacion` (datos válidos) y
  `PermisosModeracion` (quién aprueba, rechaza o borra) se usan en las capas de
  Firebase y Demo y en los ViewModels. Además, `firestore.rules` las vuelve a
  exigir en el servidor.

## 3. Bloques reutilizables

| Bloque | Ubicación | Para qué |
|---|---|---|
| `AppFlavor` | `core/config/app_flavor.dart` | Nombre, paquete, color y denominación fija de cada app |
| `arrancarApp(flavor)` | `core/di/arranque_app.dart` | Arranque común: inicializa Firebase o Demo y activa edge-to-edge |
| `Dependencias` | `core/di/dependencias.dart` | Elige Firebase o Demo **una sola vez** y envuelve los repositorios con el filtro de la app |
| Decoradores `*PorDenominacion` | `data/repositories/filtrado/` | Filtran lecturas y bloquean escrituras de otra denominación, en Firebase y en Demo, sin índices nuevos |
| `PermisosModeracion` | `data/repositories/permisos_moderacion.dart` | Admin / aprobador / creador |
| `MapaIglesias` | `ui/shared/map/` | Un widget de mapa: Google Maps si hay clave, si no OpenStreetMap |
| `SelectorUbicacionMapa` | `ui/shared/map/` | Marcar un punto (iglesia física o ministerio con sede propia) |
| `CampoDenominacion` | `ui/shared/widgets/` | Fija en las Apps 1 a 4; lista desplegable en la App 5 |
| `MargenesSistema` | `ui/shared/layout/` | Márgenes de la barra de navegación (Android 15 edge-to-edge) |
| `GeneradorRecurrencia` | `data/recurrencia/` | Recurrencia en la app (máx. 60 eventos, 16 meses) |
| `Terminologia` | `core/config/terminologia.dart` | Palabras de cada denominación (Laicado, Misa, Padre / Congregación, Culto, Pastor) |
| `FuenteImportacionOsm` | `core/config/fuente_importacion_osm.dart` | Qué archivo de OpenStreetMap importa cada app |
| Importación OSM | `data/importacion/` | Lector del JSON, planificador idempotente (`osm_<id>`), lotes y progreso |
| Reclamos | `data/repositories/reglas_reclamo.dart` + `reclamo_repository.dart` | Reclamar / gestionar una iglesia sin administrador |

## 4. Cómo se especializa cada app

1. **Android**: `android/app/build.gradle.kts` declara `productFlavors` con su
   `applicationId` y su nombre (`appLabel`). La App 1 tiene su propio ícono en
   `android/app/src/catolica/res`.
2. **Punto de entrada**: `lib/main_<flavor>.dart` llama a
   `arrancarApp(AppFlavor.<flavor>)`. `lib/main.dart` usa el `--flavor` de la
   compilación; si no hay ninguno, usa la App 1.
3. **Datos**: si la app tiene una denominación fija, `Dependencias` envuelve los
   repositorios con los decoradores de `filtrado/`. Mapa, búsqueda, eventos,
   ministerios y moderación muestran solo esa denominación, y crear algo de otra
   denominación se rechaza.
4. **Interfaz**: tema y color por app, nombre en el título, en el login y en el
   banner del Modo Demo. Los chips de denominación solo aparecen en la App 5, y
   en las Apps 1 a 4 la denominación queda fija en los formularios.
5. **Firebase**: `firebase_options.dart` comparte proyecto, claves y bucket, y
   tiene un `appId` Android/Web por app. El Modo Demo se activa por app mientras
   su `appId` tenga `PEGA_AQUI` (hoy la App 1 ya es real: proyecto `iglesias-lima`).
   En Android, cada flavor trae su `google-services.json` en
   `android/app/src/<flavor>/`; el plugin `com.google.gms.google-services` lo
   procesa por variante y, si falta, solo avisa (`missingGoogleServicesStrategy = WARN`).
6. **Claves de Google Maps** aisladas en 3 lugares: `android/gradle.properties`
   (`GOOGLE_MAPS_API_KEY` → placeholder del manifest), `core/config/maps_config.dart`
   (interruptor; o `--dart-define`) y `web/index.html`. `MapaIglesias` cae a
   OpenStreetMap si la clave es placeholder o si Google Maps falla en tiempo de
   ejecución (`MapsConfig.respaldoOsm`, `ui/shared/map/disponibilidad/`).

## 5. Flujo de aprobación

`Pendiente` → (`Aprobado` | `Rechazado`)

- Todo lo que se crea (iglesia, ministerio o evento) entra como **Pendiente** y
  solo lo ven su creador, su aprobador y el Administrador General.
- **Aprobador**: el líder (`lider_uid_ref`) de la iglesia, o de la iglesia matriz
  en el caso de un ministerio. Nadie aprueba lo que creó él mismo, salvo el
  Administrador General.
- **Rechazado**: deja de mostrarse en el mapa, pero no se borra.
- **Borrado definitivo**: solo el Administrador General.
- Pantalla: `ui/admin/moderacion_screen.dart` + `moderacion_view_model.dart`.

## 5.1 Terminología por denominación

`AppFlavor.terminologia` devuelve un `Terminologia` y la interfaz lo usa en
lugar de textos fijos. En Firestore se guardan siempre los mismos valores
(`Usuario`, `Pastor_Padre`, `Misa_Culto`…); solo cambia la etiqueta.

| Concepto | Católica (App 1) | Evangélica (App 2) | Resto |
|---|---|---|---|
| Rol `Usuario` | Usuario / Laicado | Usuario / Congregación | Usuario |
| Tipo `Misa_Culto` | Misa | Culto | Misa / Culto |
| Rol `Pastor_Padre` | Padre | Pastor | Pastor / Padre |

## 5.2 Iglesias de OpenStreetMap y reclamos

- **Datos**: `assets/importacion/iglesias_catolicas_lima_osm.json` (Lima
  Metropolitana y Callao), con su atribución **© Colaboradores de
  OpenStreetMap** (licencia ODbL 1.0) dentro del archivo y en el diálogo de
  importación. Las Apps de otras denominaciones agregan su propio archivo en
  `FuenteImportacionOsm` y reutilizan todo lo demás.
- **Filtro de denominación** (aplicado al generar el JSON):
  - *Nivel A* (`Confirmada_OSM`): `denomination=catholic` o `roman_catholic`.
  - *Nivel B* (`Por_Verificar`): `religion=christian` sin `denomination`, solo
    con marcas católicas claras en el nombre (Parroquia, Capilla, Santuario,
    Basílica, Catedral, Monasterio, Convento, o Templo/Iglesia + San/Santa/
    Santo/Santos/Nuestra Señora/Virgen/Sagrado Corazón/Cristo Rey/
    Inmaculada/Señor de). "Iglesia X" a secas no basta.
  - Siempre se excluyen nombres evangélicos, adventistas, bautistas (salvo
    "San Juan Bautista"), pentecostales, Asambleas de Dios, metodistas,
    presbiterianos, luteranos, anglicanos, "cristiana", Alianza, Iglesia del
    Nazareno, apostólicos, ministerios, misiones (salvo parroquias), Salón del
    Reino, Testigos, ortodoxos, cualquier otra `denomination` y otras religiones.
- **Modelo** (`IglesiaModel`): `origen` (`Usuario`/`OSM`), `osm_id`,
  `estado_administracion` (`Sin_Administrador` → `Reclamacion_Pendiente` →
  `Administrada`) y `verificacion_denominacion`. Las de OSM entran
  **Aprobadas** (públicas) y sin líder; el mapa y la ficha muestran
  "Sin administrador". Las de nivel B solo muestran el indicador
  "por verificar" al Administrador General.
- **Importación** (`ImportacionIglesiasRepository`): solo Admin General, desde
  Moderación → "Importar iglesias de OpenStreetMap". Usa el SDK con la sesión
  del admin (sin tokens ni API REST), id fijo `osm_<tipo>_<id>` y lotes de 400
  con progreso. Es idempotente: salta las existentes y las **descartadas**
  (`osm_descartadas`). Funciona igual en Modo Demo.
- **Verificación**: Moderación → "Por verificar" (con filtro por nombre):
  *Confirmar* pasa a `Confirmada_OSM`; *Descartar* borra la iglesia y la anota en
  `osm_descartadas` para que no vuelva a importarse.
- **Reclamo**: con sesión, la ficha de una iglesia pública sin administrador
  ofrece "Reclamar / gestionar esta iglesia". Se crea `solicitudes_reclamo/
  <idIglesia>_<uid>` (Pendiente) y la iglesia pasa a `Reclamacion_Pendiente`
  en el mismo lote. En Moderación → "Reclamos", el Admin General **aprueba**
  (la iglesia queda `Administrada` con `lider_uid_ref` = solicitante, que pasa
  a Padre/Pastor si era Usuario o Coordinador, y los demás reclamos se
  rechazan) o **rechaza** (la iglesia vuelve a `Sin_Administrador`).
- "Nueva iglesia" recuerda buscar primero en el mapa para no duplicar.

## 6. Modo Demo

Se activa cuando `firebase_options.dart` tiene `PEGA_AQUI` para la app (o si
Firebase falla al iniciar).

- Datos en memoria (`DemoDataStore` + `DemoDatosSemilla`) con 6 parroquias
  católicas aprobadas en distintos distritos, una capilla pendiente, ministerios
  y eventos en los próximos 30 días y en el historial.
- El usuario entra como Administrador General y puede cambiar de rol
  (`SelectorRolDemo`).

## 7. Cómo agregar una app nueva (p. ej. activar la App 5)

1. Registrar `pe.iglesiaslima.global` en Firebase (con la SHA-1), guardar su
   `google-services.json` en `android/app/src/global/` y pegar su `appId` en
   `firebase_options.dart`.
2. Compilar con `flutter build apk --flavor global -t lib/main_global.dart`.
3. Opcional: crear su ícono en `android/app/src/global/res/mipmap-*`.

No hace falta cambiar ViewModels, repositorios ni pantallas.
