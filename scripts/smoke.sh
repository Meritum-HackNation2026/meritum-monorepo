#!/usr/bin/env bash
# Lokalny test dymny całego systemu (nigdy w CI): buduje i uruchamia compose,
# czeka na /api/v1/health i wysyła jedno sprawdzenie tekstu na stubie modelu.
#   scripts/smoke.sh            # zostawia system uruchomiony
#   SMOKE_DOWN=1 scripts/smoke.sh   # po teście zatrzymuje compose
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

api=${SMOKE_API:-http://localhost:8080/api/v1}
timeout=${SMOKE_TIMEOUT:-300}

if [ "${SMOKE_DOWN:-0}" = 1 ]; then trap 'docker compose down' EXIT; fi

docker compose up --build --detach

echo "Czekam na $api/health (do ${timeout}s)..."
deadline=$((SECONDS + timeout))
until curl --silent --fail "$api/health" >/dev/null; do
  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "API nie jest gotowe po ${timeout}s:" >&2
    curl --silent "$api/health" >&2 || true
    docker compose logs --tail 50 api worker >&2
    exit 1
  fi
  sleep 3
done
echo "API gotowe."

session=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
check=$(curl --silent --show-error --fail \
  -H 'Content-Type: application/json' -H "X-Meritum-Session: $session" \
  -d '{"channel":"web","text":"Od 1 stycznia 2026 płaca minimalna wynosi 4806 zł"}' \
  "$api/checks")
check_id=$(printf '%s' "$check" | sed -n 's/.*"check_id":"\([^"]*\)".*/\1/p')
[ -n "$check_id" ] || { echo "Brak check_id w odpowiedzi: $check" >&2; exit 1; }
echo "Sprawdzenie $check_id przyjęte."

deadline=$((SECONDS + 120))
while :; do
  result=$(curl --silent --fail -H "X-Meritum-Session: $session" "$api/checks/$check_id" || true)
  case $result in
    *'"result":{'*) echo "Wynik: $result"; echo "Test dymny przeszedł."; exit 0 ;;
  esac
  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "Brak wyniku po 120 s: $result" >&2
    docker compose logs --tail 50 worker >&2
    exit 1
  fi
  sleep 2
done
