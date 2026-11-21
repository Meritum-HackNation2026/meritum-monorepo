---
name: meritum-issue-writing
description: Use when creating, rewriting, splitting or triaging a GitHub issue or epic for Meritum (any repo in the Meritum-HackNation2026 org), or when turning user stories (US-XXX-NN) and features (F-NN) from the product document into issues. Gives the title rule, sections, Gherkin, criteria, labels, target repo, size and the gh commands.
---

# Writing Meritum issues

Issues say **what** and **why**. **How** goes into the PR (or, briefly, into Notes).
The org-wide issue forms in `Meritum-HackNation2026/.github` (`.github/ISSUE_TEMPLATE/`) have the
same headings; an issue filed by `gh issue create --body-file` must use them too.

With a human in the session and open decisions in the story, run `mattpocock-skills:grilling`
before drafting. Working alone, write the open decisions under Notes as questions for triage.

Language: issue text in **Polish** (the team, the product document and the READMEs are Polish).
Headings, the `feat:`/`bug:` prefix, label names and Gherkin keywords stay in **English**, so
agents and scripts can parse them.

## Title

`<type>: <outcome in plain words>`, lower case after the prefix, no trailing period.

| Prefix | Use for | Example |
|---|---|---|
| `feat:` | new behavior someone can observe | `feat: formularz przyjmuje link i pobiera publiczną stronę bez SSRF` |
| `bug:` | observed symptom | `bug: karta pokazuje siłę przy werdykcie „brak wystarczających dowodów”` |
| `chore:` | tooling, CI, refactoring, dependencies | `chore: kontrakty sprawdzania podzielone na moduły do 250 linii` |
| `docs:` | documentation only | `docs: README opisuje klucze, limity i region przetwarzania` |
| `epic:` | tracking issue for a domain | `epic: E3 Źródła, dowody i werdykt` |

Describe the outcome, not the task ("formularz pokazuje…", not "zaimplementuj formularz").

## Body (feature / chore)

~~~markdown
### Context
Who needs it, in what situation, what it costs today. Name the stories and features:
"Historie: US-SPR-01, US-SPR-07. Funkcje: F-01, F-06." Link ADRs (ADR-NN) when they decide something.

### Expected behavior
```gherkin
Scenario: <one observable behavior>
  Given ...
  When ...
  Then ...
```

### Criteria of success
- [ ] verifiable item naming the interface: type, function, endpoint or component (`compute_strength`, `VerdictBadge`); a file path only when the file already exists
- [ ] tests: behave scenario `features/<domain>.feature` (Python) or `node --test` file (TypeScript); pytest unit tests
- [ ] docs: README / docstrings with `Features: US-..., F-...` (see meritum-architecture)
- [ ] checks green, named by tool: Python `ruff check` (C901 ≤ 10), `ruff format --check`, `ty check`, `scripts/check_conventions.py`, `pytest` with `tests/architecture/`, `vulture`, `bandit`; TypeScript `biome ci`, `tsc`, `pnpm test` with `tests/architecture/`, `pnpm depcruise`, `pnpm knip`

### Area
<domain> / <component>, e.g. `evidence / core`

### Notes
`Out of scope:` what the implementer leaves alone (the Spec reviewer flags work beyond the
issue against it); open questions; constraints. Dependencies go here as
`Depends on Meritum-HackNation2026/meritum-core#12` (one per line).
~~~

Bug body: `### Context` (version or commit, environment dev/prd, steps, observed vs expected),
`### Why is it bad`, `### Severity` (critical | major | minor | trivial),
`### Recommended / proposed fix` (optional).

### Gherkin

- English keywords (`Scenario`, `Given`, `When`, `Then`, `And`), Polish step text. behave runs it
  as is; the scenario is copied into `features/<domain>.feature` by whoever implements it.
- One scenario per behavior, 1 to 4 per issue. Use concrete values from the product document
  (4000 znaków, 30 s, 5 twierdzeń), never "fast" or "many".
- UI-only issues may use Gherkin too; the matching test runs under `node --test` (`pnpm test`), not behave; the TS repos have no vitest.

### Criteria of success

Each item must be checkable by someone who did not write the issue. Always include:
1. the behavior items (one per acceptance criterion of the story that this issue covers);
2. tests that prove them (behave for Python behavior, pytest for units, `node --test`
   for TS). An e2e or cross-component test, if needed, is a manual/local script, never a CI job;
3. docstrings/JSDoc naming the story and feature IDs, and any README or doc that changes;
4. "Architecture and convention checks pass" when code is added.
5. for UI issues: "Follows the design system (meritum-ui): tokens, components, texts from
   `copy/pl.json`, WCAG 2.2 AA in light and dark", and the copy keys the issue needs.

## Which repo

| Repo | Gets issues for |
|---|---|
| `meritum-core` | contracts (`checks/contracts`), ports, adapters and factories shared by backend and worker, pure domain rules (verdict, strength, citation check, masking, normalization) |
| `meritum-backend` | FastAPI endpoints, inbound channel adapters (WWW API, Discord, SMS, MCP), limits, readiness, SSE, staff auth |
| `meritum-worker` | DBOS workflows: the check pipeline, ingestion, RSS, EUvsDisinfo, retention, evaluation runs |
| `meritum-frontend` | the web app: form, result card, notifications, moderator panel, evaluation page |
| `meritum-extension` | the Chrome MV3 extension |
| `meritum-mocks` | platform mocks and the Discord mock |
| `meritum-infra` | GCP / on-prem deployment, runners |
| `meritum-design-system` | copy (`copy/pl.json`), tokens, components spec, product document |
| `meritum-marketing` | deck, film, contest materials |
| `meritum-monorepo` | epics, cross-repo work (docker compose, root README) |

One issue = one repo = one PR. If a story spans repos (most do), split it: contract or rule in
core, workflow in worker, endpoint in backend, UI in frontend, each depending on the previous.

## Labels

Every issue gets exactly one of each group, except `area`, which may repeat:

- `type: feature | bug | chore | docs | epic`
- `status: triage` on creation (a human moves it to `status: ready`; agents start only on ready)
- `area: checks | channels | evidence | corpus | security | moderation | observability | deploy | notifications | architecture`
  (the product document's domains; story prefix SPR/DST → checks, WTY → channels, ZRD → evidence,
  KOR → corpus, BEZ → security, MOD → moderation, OBS → observability, WDR → deploy, POW → notifications)
- `size: S` (a few hours), `size: M` (about half a day), `size: L` (more: split it unless it cannot be split)
- `priority: mvp | if time | after hackathon` (the story's priority; take the highest of the covered stories)

`agent`, `status: in progress|in review|blocked` and `review: …` are set by the claiming and
review skills, never when filing. The label set is defined in `scripts/setup-labels.sh`.

## Epics

One epic per domain in `meritum-monorepo`, titled `epic: E<n> <domain name>`, labels
`type: epic`, `status: triage`, `area: <domain>`. Body: Context (the domain and its stories),
Expected behavior (one end-to-end Given/When/Then), Criteria of success as a task list of the
child issues (`- [ ] Meritum-HackNation2026/meritum-core#12`). Link each child as a GitHub
sub-issue when the API allows it (it does across repos in one org):

```bash
id() { gh api "repos/Meritum-HackNation2026/$1/issues/$2" --jq .id; }
gh api repos/Meritum-HackNation2026/meritum-monorepo/issues/<epic>/sub_issues -F sub_issue_id="$(id meritum-core 12)"
```

## Drafts and filing

Drafts live in `issues/drafts/<repo>/<NNN>-<slug>.md` with frontmatter:

```yaml
---
repo: meritum-core
title: "feat: ..."
labels: ["type: feature", "status: triage", "area: evidence", "size: M", "priority: mvp"]  # quoted: they contain ": "
stories: [US-ZRD-03, US-ZRD-04]
features: [F-15]
depends_on: [core/001]          # draft IDs <dir>/<NNN>, any repo
epic: E3
size: M
---
```

`scripts/publish-issues.sh` files them in dependency order, idempotent by title
(`--dry-run` prints the plan). To file one issue by hand:

```bash
gh issue list -R Meritum-HackNation2026/<repo> --state all --search "in:title <keywords>"   # search first
gh issue create -R Meritum-HackNation2026/<repo> --title "feat: ..." \
  --label "type: feature" --label "status: triage" --label "area: evidence" --label "size: M" \
  --body-file body.md
```

## Rules

- One problem per issue. Criteria spanning two repos or two domains mean two issues.
- Never put secrets, tokens, real personal data or the hidden jury set in an issue.
- No AI attribution anywhere (no "Generated with…", no robot emoji, no session links).
- When the product document changes a story, update the issue and say so in a comment.
