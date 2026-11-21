#!/usr/bin/env bash
# Turns on the gitleaks pre-push hook (.githooks/pre-push) in the monorepo and in
# every submodule: a push with a secret is blocked before it leaves the machine.
# Usage: scripts/setup-git-hooks.sh   (once per clone; needs gitleaks: brew install gitleaks)
set -euo pipefail
cd "$(dirname "$0")/.."

command -v gitleaks >/dev/null ||
  echo "warning: gitleaks is not installed (brew install gitleaks); until it is, every push is blocked" >&2

git config core.hooksPath .githooks
echo "hooks on: meritum-monorepo"
git submodule foreach --quiet 'git config core.hooksPath .githooks && echo "hooks on: $name"'
