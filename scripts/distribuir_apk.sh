#!/usr/bin/env bash
# Sube un APK ya compilado a Firebase App Distribution.
#
# Uso:
#   scripts/distribuir_apk.sh <flavor> <ruta_apk> "<notas de la versión>" [testers]
#
#   flavor   catolica | evangelica | jehova | ijsud | global
#   testers  correos separados por coma (por defecto: jeremyvillanueva@gmail.com)
#
# Variables opcionales: FIREBASE_BIN (por defecto: firebase en el PATH o
# ~/.local/bin/firebase) y FIREBASE_PROJECT (por defecto: iglesias-lima).
# Usa la sesión de `firebase login`; no necesita ni guarda tokens.
set -euo pipefail

if [[ $# -lt 3 ]]; then
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 64
fi

FLAVOR="$1"
APK="$2"
NOTAS="$3"
TESTERS="${4:-jeremyvillanueva@gmail.com}"
PROYECTO="${FIREBASE_PROJECT:-iglesias-lima}"

if [[ -n "${FIREBASE_BIN:-}" ]]; then
  FB="$FIREBASE_BIN"
elif command -v firebase >/dev/null 2>&1; then
  FB="$(command -v firebase)"
else
  FB="$HOME/.local/bin/firebase"
fi

# App ID de Firebase (Android) de cada flavor. Las apps que aún no están
# registradas en Firebase quedan vacías y el script se detiene.
case "$FLAVOR" in
  catolica)   APP_ID="1:229289277006:android:c263b9e76af88e5227751f" ;;
  evangelica) APP_ID="1:229289277006:android:21d73df3ca75b30727751f" ;;
  jehova|ijsud|global) APP_ID="" ;;
  *) echo "Flavor desconocido: $FLAVOR" >&2; exit 64 ;;
esac

if [[ -z "$APP_ID" ]]; then
  echo "La app '$FLAVOR' aún no está registrada en Firebase: agrega su App ID en $0." >&2
  exit 65
fi
if [[ ! -f "$APK" ]]; then
  echo "No existe el APK: $APK" >&2
  exit 66
fi

echo "Distribuyendo $APK ($FLAVOR) a: $TESTERS"
exec "$FB" appdistribution:distribute "$APK" \
  --app "$APP_ID" \
  --project "$PROYECTO" \
  --testers "$TESTERS" \
  --release-notes "$NOTAS"
