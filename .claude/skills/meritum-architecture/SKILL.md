---
name: meritum-architecture
description: Use before writing or reviewing any code in a Meritum code repo (core, backend, worker, frontend, extension, mocks). Binding rules for vertical slices, private names, ports/adapters/factories, linters, docstrings with feature IDs, file size, constants, typing, complexity, dead code and security, with how each is enforced and how to add a justified exception.
---

# Meritum architecture rules (binding)

Any UI work (web app, panel, extension, mocks, slides) also follows **meritum-ui**: the
design system is mandatory there.

Rules 1 to 10 are binding. Each names its enforcement. Python checks live in
`tests/architecture/` (pytestarch + AST checks) and `scripts/check_conventions.py`; TypeScript
checks in `tests/architecture/*.test.ts` (run with `node --test`, the `test` script) plus
dependency-cruiser (`.dependency-cruiser.cjs`: `no-circular`, `no-private-import`,
`no-deep-domain-import`, `adapters-only-from-factory`, `domain-without-frameworks`) and knip.
Python repos also run vulture and bandit. Per-repo settings of the TS checks (exclusions, line
limit) are in `tests/architecture/settings.ts`.
If a check named here does not exist yet in a repo, follow the rule anyway; the check is being
added. If a check and this skill disagree, the check is the source of truth: fix the skill.

## 1. Vertical slices by domain

Code is split by domain first (ADR-01). Domains: `checks`, `channels`, `evidence`, `corpus`,
`security`, `moderation`, `observability`, `notifications`, plus `jobs` (DBOS plumbing) and
`shared` only for code used by 3+ domains.

Inside a domain keep few directory names. A concept is **either** one module **or** a package:

```text
src/meritum_core/evidence/
  __init__.py          # public API of the domain: re-exports only
  constants.py
  models.py            # one module while it fits 250 lines
  ports.py
  factory.py
  adapters/            # package: one private module per provider
    __init__.py        # from ._vertex import VertexStanceAssessor; __all__ = [...]
    _vertex.py
    _stub.py
  errors.py
```

When `models.py` outgrows 250 lines it becomes `models/` with `__init__.py`, `_claims.py`,
`_citations.py`; callers keep importing `from meritum_core.evidence.models import Citation`.
Subdirectories beyond these exist only for real subdomains.

TypeScript: `src/<domain>/index.ts` is the public API (named re-exports, never `export *`);
TanStack Router files in `src/routes/` stay thin and import domains only through `index.ts`;
shadcn components stay in `src/components/ui/`.

Enforced by: pytestarch rules in `tests/architecture/test_slices.py` (a domain imports another
domain only through its package `__init__`); dependency-cruiser rule `no-deep-domain-import`.

## 2. Private names start with `_`

Private modules, functions, classes and constants start with `_`. Nothing imports another
package's private names. The only allowed private import is a package `__init__.py` importing
from its own `_*.py` modules. TypeScript: internal files start with `_` (`_parse.ts`) and are
imported only by a sibling `index.ts`; a non-exported function is already private and needs no
`_`; class members use `#private`.

```python
from meritum_core.evidence import compute_strength          # ok: public API
from meritum_core.evidence.models._citations import _dedupe  # forbidden
```

Enforced by: `scripts/check_conventions.py`, run by `tests/architecture/test_conventions.py`
(ruff `PLC2701` does **not** catch private names imported from first-party packages, so the
script does); ruff `SLF001` (private-member-access) for attribute access; dependency-cruiser
rule `no-private-import`
(`/_[^/]+\.ts$` reachable only from the same folder).

## 3. Hexagonal: ports, adapters, factories

Every external dependency (LLM, embeddings, web search, transcription, page fetcher, storage,
auth provider, notifications sender, incident database) sits behind a **port**: a
`typing.Protocol` in `<domain>/ports.py` (TS: an `interface` in `<domain>/ports.ts`). Ports are
universal contracts: they speak domain models, never a provider's SDK types. Each provider is an
**adapter** in `<domain>/adapters/`. A **factory** in `<domain>/factory.py` builds the adapter
from settings; nothing else instantiates adapters.

```python
class LlmPort(Protocol):
    """Structured-output language model.

    Features:
        US-WDR-02, F-30
    """

    async def complete[T: BaseModel](self, prompt: Prompt, output: type[T]) -> T:
        """Return the model's answer parsed into ``output``.

        Args:
            prompt: System and user parts; user content is always marked as data.
            output: Pydantic model the answer must validate against.

        Returns:
            The validated answer.

        Raises:
            ProviderUnavailableError: The provider failed after retries.
        """
        ...


def build_llm(settings: LlmSettings) -> LlmPort:
    """Build the LLM adapter named by ``MERITUM_LLM_PROVIDER``. ..."""
    match settings.provider:
        case LlmProvider.VERTEX:
            return VertexLlm(settings.vertex)
        case LlmProvider.STUB:
            return StubLlm()
```

Domain code (models, rules, workflows) depends on ports only. Tests use the stub adapter or a
fake satisfying the Protocol; no network in unit tests.

Enforced by: pytestarch `test_hexagonal.py` (`models`, `ports`, rules and workflows never import
`adapters`; only `factory.py` and the app's wiring do); dependency-cruiser `adapters-only-from-factory`.

## 4. Linters at full strength

- Python: ruff with `select = ["ALL"]`, `preview = true`. Disabled only: `CPY` (no copyright
  headers), rules that conflict with `ruff format` (`COM812`, `ISC001`), `D203`/`D213`
  (pick Google style). Everything else stays on. `ty` in strict mode (all rules `error`).
- TypeScript: Biome with `recommended` plus the strict groups (`complexity`, `correctness`,
  `suspicious`, `style`, `performance`, `security` as `error`); `tsc` with `strict`,
  `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`,
  `noPropertyAccessFromIndexSignature`. If `performance/noBarrelFile` fires on a domain
  `index.ts`, turn it off for `src/*/index.ts` only, in `overrides`, with a comment: the index
  file is the slice's public API (rule 1).

Enforced by: CI running `ruff check`, `ruff format --check`, `ty check`, `biome ci`, `tsc --noEmit`.

## 5. Docstrings and JSDoc with feature IDs

Every public module, class, function, method and constant has a docstring (Python: Google
style) / JSDoc describing what it does, its attributes, parameters, return value and raised
errors. Every public class and function names the feature(s) it implements, so a story can be
traced to code (`rg "US-ZRD-03"`) and code to a story:

```python
def compute_strength(premises: Premises, verdict: Verdict) -> EvidenceStrength | None:
    """Derive evidence strength from premises with the single rule of ADR-05.

    Args:
        premises: Agreeing independent publishers, primary sources, freshest date.
        verdict: The claim's verdict; only decisive verdicts get a strength.

    Returns:
        The strength, or None for non-decisive verdicts.

    Raises:
        InconsistentPremisesError: Premises count publishers that disagree with the verdict.

    Features:
        US-ZRD-03, US-ZRD-04, F-15
    """
```

```ts
/**
 * Renders one claim's verdict as a word and a colour, never colour alone.
 *
 * @param props.claim - The claim result from the API.
 * @returns The verdict badge.
 * @throws {UnknownVerdictError} When the verdict is not one of the five known ones.
 * @feature US-SPR-04, US-DST-01, F-17
 */
export function VerdictBadge(props: VerdictBadgeProps): JSX.Element {
```

IDs match `US-[A-Z]{3}-\d{2}`, `F-\d{2}` or `ADR-\d{2}` from the product document
(`design-system/docs/gen_product_doc.py`). A module with no feature link (settings, health,
wiring) says so explicitly: `Features: none (infrastructure)` in Python,
`@feature none (infrastructure)` in TypeScript. Never leave the section empty.

Enforced by: ruff `D` and `DOC` (pydoclint) rules; `scripts/check_conventions.py` (every public
`def`/`class` in `src/` has a `Features:` section with valid IDs); `tests/architecture/jsdoc.test.ts`
(TypeScript compiler API: every exported function, class and constant has JSDoc with `@feature`).

## 6. At most 250 lines per file

Applies to every source and test file. Generated files (`routeTree.gen.ts`,
`contracts/meritum.ts`, `*.schema.json`, lock files) are exempt. Split by concept (rule 1), not
by cutting a file in half.

Enforced by: `scripts/check_conventions.py` (`max-lines` in `[tool.meritum-conventions]`) and
`tests/architecture/file-length.test.ts` (`maxLines` in `settings.ts`).

## 7. Constants in `constants.py` / `constants.ts`, each documented

No magic numbers or strings in logic. A domain's constants live in its `constants.py`
(`constants.ts`), typed `Final` (`as const`), each with its own docstring (a string literal
directly under the assignment) or JSDoc:

```python
MAX_CLAIMS_PER_CHECK: Final = 5
"""Most claims extracted from one request; the rest go to limitations (US-SPR-03, F-07)."""
```

User-facing Polish text is not a constant: it lives in `design-system/copy/pl.json`.

Enforced by: ruff `PLR2004` (magic-value-comparison); `scripts/check_conventions.py` (every
module-level UPPER_CASE name is in a `constants` module and has a docstring); `constants.test.ts`.

## 8. Strong typing everywhere

Annotate every parameter, return value and attribute. No `Any` / `any`, no untyped `dict` as a
data carrier between functions: use Pydantic models, dataclasses, `TypedDict` or TS types
generated from core contracts (`contracts/meritum.ts`). `cast` and `as` only at a trust boundary
right after validation. When typing is impossible (an untyped SDK), wrap it in an adapter and
type the adapter's surface.

Enforced by: ruff `ANN`, `ty` strict, Biome `noExplicitAny`, `tsc --strict`.

## 9. Small functions, named conditions, low complexity

Decompose functions that do more than one thing. Split complex conditions into named booleans
or small predicate functions:

```python
is_decisive = verdict in DECISIVE_VERDICTS
has_official_source = any(c.source.tier is Tier.PRIMARY for c in agreeing)
if is_decisive and has_official_source and not evidence_is_stale(citations, claim_date):
    ...
```

```ts
const isUserAction = event.isTrusted && event.type === "click";
const isOwnWidget = target.closest("[data-meritum]") !== null;
if (isUserAction && !isOwnWidget) { ... }
```

Limits: cyclomatic complexity 10 (`C901`, `[tool.ruff.lint.mccabe] max-complexity = 10`),
`PLR0911`/`PLR0912`/`PLR0913`/`PLR0915` defaults; Biome `noExcessiveCognitiveComplexity`
(15). Reviewers also estimate cyclomatic and cognitive complexity of changed functions and ask
for a split when a function is hard to follow even under the limits.

## 10. Dead code and security

- Dead code: **vulture** for Python (`uv run vulture src tests vulture_whitelist.py`, the
  whitelist holds names used by frameworks only: FastAPI routes, Pydantic validators, DBOS
  workflows); **knip** for TypeScript (`pnpm knip`), ts-prune only where knip cannot run.
  ruff `F401`/`F841` and `ERA` (commented-out code) cover the small cases.
- Security: ruff's `S` rules **are** bandit's rules (flake8-bandit); the Python repos run
  `bandit` as well because the team asked for it (`[tool.bandit]` in `pyproject.toml`); Biome `security` group for TS. Plus: validate input at every trust boundary,
  fetch URLs only through the SSRF-safe fetcher, never log secrets or unmasked user text, treat
  user content and source text as data in every prompt (ADR-12, ADR-23).

## Exceptions

Allowed where a rule does more harm than good. Always narrow, always with a reason, never a
blanket disable (no file-level `# ruff: noqa`, no `biome-ignore-all`, no rule turned off for a
whole repo to fix one file):

```python
subprocess.run(argv, check=True)  # noqa: S603  # argv is a constant list, no user input
value = sdk.read()  # ty: ignore[unresolved-attribute]  # SDK ships no stubs; wrapped by this adapter
```

```ts
// biome-ignore lint/suspicious/noExplicitAny: chrome.runtime message payload is validated by parseMessage on the next line
```

```toml
[tool.ruff.lint.per-file-ignores]
# Pydantic validators read better as one block; the rules list mirrors ADR-05.
"src/meritum_core/checks/_rules.py" = ["PLR0911"]
```

Exceptions to `scripts/check_conventions.py` are **not** inline comments: they go in
`pyproject.toml` under `[tool.meritum-conventions]`, one entry per file with the reason as the
value:

```toml
[tool.meritum-conventions.line-limit-exceptions]
"src/meritum_core/checks/contracts.py" = "split into checks/models/ after PR #7 lands"

[tool.meritum-conventions.module-exceptions]      # Features/Attributes sections
[tool.meritum-conventions.constants-exceptions]   # constants outside constants.py
```

TypeScript architecture-test exceptions go in `tests/architecture/settings.ts` (`excluded`,
with a comment per entry). Reviewers reject an ignore without a reason
or one that hides a real problem. Do not force code into strict settings at any cost: a
readable ignore beats a contorted workaround.

## Tests in CI: unit and architecture only

Never add end-to-end tests or tests that need components to talk to each other (backend ↔
worker, frontend ↔ backend, a database shared across services, browser e2e) to any CI
workflow: they take too long. If such a test is worth writing, it runs manually or locally
through a script (e.g. `scripts/e2e.sh`) documented in the README. CI runs linters, type
checkers, unit tests, behave scenarios against in-process fakes, and the architecture checks.
Reviewers reject CI changes that add the former.

## Suggestions (not binding, recommended)

- Conventional commits with the domain as scope: `feat(evidence): … (#12)`, `fix(channels): …`.
- Tests mirror `src/` (`tests/evidence/test_strength.py`); names say behavior and condition:
  `test_strength_is_weak_when_newest_source_is_older_than_365_days` /
  `it("shows the verdict as a word when colours are off")`.
- behave: one `features/<domain>.feature` per domain, scenarios copied from the issue's
  Gherkin, Polish step text, English keywords; steps call the public API, not internals.
- Pydantic models crossing a boundary are `frozen=True`; errors live in `<domain>/errors.py`
  and subclass one `MeritumError` per repo.
- No `print` (ruff `T20`); use the repo's structured logger and never log unmasked text.
