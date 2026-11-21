#!/usr/bin/env bash
# Przesuwa wszystkie submoduły na aktualny main z GitHuba i commituje zmianę.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
git submodule update --init --remote --merge
git add design-system infra org-profile core backend worker frontend mocks extension marketing
if git diff --cached --quiet; then
  echo "Submoduły są aktualne."
  exit 0
fi
git commit -m "Zaktualizuj submoduły do najnowszego main"
