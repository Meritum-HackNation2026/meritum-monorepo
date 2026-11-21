#!/usr/bin/env bash
# Creates or updates the Meritum label set in every org code repo (gh label create --force).
# Usage: scripts/setup-labels.sh [repo ...]   (default: all repos below; needs gh with repo scope)
set -euo pipefail

ORG=Meritum-HackNation2026
REPOS=("$@")
if [ ${#REPOS[@]} -eq 0 ]; then
  REPOS=(meritum-monorepo meritum-core meritum-backend meritum-worker meritum-frontend
         meritum-extension meritum-mocks meritum-infra meritum-design-system meritum-marketing)
fi

# name|color|description
LABELS=(
  "type: feature|1d76db|New capability or use case"
  "type: bug|d73a4a|Something that should work is broken"
  "type: chore|c5def5|Tooling, CI, dependencies, refactoring"
  "type: docs|0075ca|Documentation only"
  "type: epic|3e4b9e|Tracking issue for a domain"
  "status: triage|fbca04|New; needs review before work starts"
  "status: ready|0e8a16|Clear and accepted; anyone may claim it"
  "status: in progress|5319e7|Claimed; someone (human or agent) is working on it"
  "status: in review|006b75|PR open, waiting for review"
  "status: blocked|b60205|Cannot proceed; the reason is in a comment"
  "agent|8a63d2|Being worked on by an AI agent"
  "area: checks|bfdadc|Checking flow: input, claims, verdict states (US-SPR, US-DST)"
  "area: channels|bfd4f2|Web form, extension, Discord, SMS, MCP (US-WTY)"
  "area: evidence|c2e0c6|Sources, citations, verdict and strength (US-ZRD)"
  "area: corpus|d4c5f9|Catalog, corpus, search, ingestion (US-KOR)"
  "area: security|f9d0c4|Prompt injection, privacy, limits (US-BEZ)"
  "area: moderation|fef2c0|Moderator cases and panel (US-MOD)"
  "area: observability|c5def5|Check records, evaluation, export (US-OBS)"
  "area: deploy|e6e6e6|Deployment, configuration, contest materials (US-WDR)"
  "area: notifications|d1bcf9|Toasts, inbox, e-mail and webhooks (US-POW)"
  "area: architecture|ededed|Conventions, linters, architecture checks"
  "size: S|ededed|A few hours"
  "size: M|cccccc|About half a day"
  "size: L|999999|More than half a day; consider splitting"
  "priority: mvp|0e8a16|Built for the hackathon"
  "priority: if time|fbca04|Bonus feature, after the MVP"
  "priority: after hackathon|cfd3d7|Planned for later"
  "review: round 1|c2e0c6|First review round"
  "review: round 2|fef2c0|Second review round"
  "review: round 3|f9d0c4|Third and last review round"
  "review: needs human|b60205|Not approved after 3 rounds; a human decides"
)

for repo in "${REPOS[@]}"; do
  echo "== $ORG/$repo"
  for entry in "${LABELS[@]}"; do
    IFS='|' read -r name color description <<< "$entry"
    gh label create "$name" --repo "$ORG/$repo" --color "$color" --description "$description" --force
  done
done
