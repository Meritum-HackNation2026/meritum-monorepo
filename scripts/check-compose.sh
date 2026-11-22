#!/usr/bin/env bash
# Lokalny test konfiguracji compose (bez uruchamiania kontenerów, nigdy w CI):
# usługa gateway istnieje tylko z profilem discord i używa obrazu backendu.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

fail() { echo "BŁĄD: $1" >&2; exit 1; }

default=$(docker compose config --services)
grep -qx gateway <<<"$default" && fail "gateway startuje bez profilu discord"
for s in db worker api web mocks; do
  grep -qx "$s" <<<"$default" || fail "brak usługi $s w domyślnym zestawie"
done

with=$(COMPOSE_PROFILES=discord docker compose config --services)
grep -qx gateway <<<"$with" || fail "profil discord nie dodaje usługi gateway"

# token z .env: tymczasowy plik, jeśli nie ma prawdziwego (prawdziwy .env musi mieć token)
if [ ! -e .env ]; then echo MERITUM_DISCORD_BOT_TOKEN=x >.env; trap 'rm -f .env' EXIT; fi
cfg=$(COMPOSE_PROFILES=discord docker compose config --format json)
jq -e '.services.gateway.command == ["python","-m","meritum_backend.discord.gateway"]' <<<"$cfg" >/dev/null \
  || fail "gateway nie uruchamia python -m meritum_backend.discord.gateway"
jq -e '.services.gateway.build.context == .services.api.build.context' <<<"$cfg" >/dev/null \
  || fail "gateway nie buduje się z obrazu backendu"
jq -e '.services.gateway.environment.MERITUM_DISCORD_BOT_TOKEN | length > 0' <<<"$cfg" >/dev/null \
  || fail "gateway nie dostaje MERITUM_DISCORD_BOT_TOKEN z .env"
echo "OK: compose ma usługę gateway w profilu discord."
