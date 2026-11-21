---
name: meritum-pr-review-loop
description: Use when a Meritum issue's implementation is ready for a pull request, and for every review round after that. Covers self-review, opening the PR to develop, two-axis review by fresh reviewer subagents, fixing findings, the three-round limit with review labels, merging and escalating to a human.
---

# PR and review loop

Flow in code repos: `<type>/<n>-<slug>` → PR to `develop` → (humans) PR `develop` → `main`.
Agents never push to `develop` or `main` directly and never open the `develop` → `main` PR.

## 1. Before the PR

- Every criterion of success in the issue is met, or the PR says which one is not and why.
- Self-review: invoke `mattpocock-skills:code-review` with fixed point `origin/develop`, the
  issue as the spec (`gh issue view <n> -R <repo>`), and `.claude/skills/meritum-architecture/SKILL.md`
  (plus `meritum-ui/SKILL.md` for UI) as the standards sources. Fix every Standards violation and
  Spec gap it reports. It is not review round 1.
- All checks pass locally, the same ones CI runs (see the repo README / justfile):
  Python `uv run ruff format --check . && uv run ruff check . && uv run ty check && uv run pytest && uv run behave`
  plus `uv run vulture` and `uv run python scripts/check_conventions.py`;
  TypeScript `pnpm biome ci . && pnpm tsc --noEmit && pnpm test && pnpm knip && pnpm depcruise`
  (`pnpm test` runs `node --test`, including `tests/architecture/`)
  (use the repo's script names when they exist).
- Commits: conventional commits with the domain as scope, issue number at the end:
  `feat(evidence): liczy siłę dowodów regułą z przesłanek (#12)`.
- **No AI attribution** in commits, PR titles or bodies: no `Co-Authored-By` for an AI, no
  "Generated with…", no robot emoji, no session links.
- If a humanizer skill is available (`humanizer:humanizer` or `anthropic-skills:humanizer`),
  run the commit messages, PR title and PR body through it before `git commit` / `gh pr create`.

## 2. Open the PR

```bash
git push -u origin HEAD
gh pr create --base develop --title "feat: <same outcome as the issue title>" --body-file pr.md
gh issue edit <n> --add-label "status: in review" --remove-label "status: in progress"
```

`pr.md` follows the org PR template (`.github/pull_request_template.md`): its headings and
checklist stay, and `mattpocock-skills:pr` fills three of them: the smallest view that makes
the change clear (call tree, file tree or diff sketch) under „Co i dlaczego”, before/after
under „Dowód” (the failing then passing test; light/dark screenshots for UI), the door and
blast radius under „Ryzyko scalenia”. Cross-repo issue:
`Closes Meritum-HackNation2026/meritum-core#12`.

## 3. Review round (repeat at most 3 times)

1. Label the round: `gh pr edit <pr> --add-label "review: round <k>"` (remove `round <k-1>`).
2. Start **two fresh reviewer subagents in parallel** (new contexts, not forks of the author),
   one per axis of `mattpocock-skills:code-review`, so neither axis masks the other. Give each
   only: the repo and PR number, the issue number, the output of `gh pr diff <pr>`, its brief
   below, and in rounds 2 and 3 the previous review comments. The Standards reviewer also gets
   the path of `.claude/skills/meritum-architecture/SKILL.md` (plus `meritum-ui/SKILL.md` when
   the diff touches UI, styles, copy or slides). Never pass the author's own summary or
   conclusions; the reviewers read the code.
3. Briefs (paste as is, filling the placeholders):

   > **Standards.** Review PR <repo>#<pr> on the Standards axis. Read the diff and the
   > meritum-architecture skill. Check: architecture rules (slices, `_` privacy,
   > ports/adapters/factories, 250-line files, constants, typing, docstrings with `Features:`
   > IDs); for UI changes the meritum-ui checklist (tokens, fonts, components, copy from
   > `copy/pl.json`, verdict colours, never colour alone, WCAG 2.2 AA light and dark, only
   > platform skins may deviate, any other deviation justified in the PR); CI changes (reject any
   > workflow change that adds e2e tests or tests needing backend/worker/frontend/database
   > contact); security (input validation, SSRF, secrets, injection); complexity. Smells from
   > the baseline of `mattpocock-skills:code-review` go under Suggestions as judgement calls.
   > Add `Complexity`: the most complex changed functions, their cyclomatic/cognitive estimate
   > and whether to split them.

   > **Spec.** Review PR <repo>#<pr> on the Spec axis against issue #<n> (`gh issue view`).
   > Quote the issue line for each finding: criteria of success or Gherkin scenarios missing or
   > partial; behaviour nobody asked for (scope creep, anything under Out of scope); behaviour
   > that looks implemented but wrong, including edge cases; tests that would pass without the
   > change or sit below the public seams named in the claim comment.

   Both: post one review with `gh pr review <pr> --comment --body-file review.md`. The body
   starts with `Axis: standards` or `Axis: spec`, then `Verdict: approve` or
   `Verdict: changes requested`; `Required fixes` as a numbered list with file:line and why;
   `Suggestions` (optional, not blocking). Approve only with no required fixes.

   Reviews use `--comment` because GitHub refuses approve/request-changes on a PR opened by the
   same account; the `Verdict:` lines are what count. The round passes only when both axes
   approve.
4. The author fixes every required fix in new commits (no force-push during review): a
   behaviour fix test-first (`mattpocock-skills:tdd`), a reported defect with no obvious cause
   through `mattpocock-skills:diagnosing-bugs`. Then one PR comment answering each point
   ("Standards 1: fixed in <sha>", "Spec 2: not changed because …"), and the next round with two new
   reviewer subagents.

The author never approves its own PR. Round 1 is always an independent review, even for a
one-line change.

## 4. Finish

- **Approved** (both latest verdicts `approve`, CI green, branch up to date with `develop`):
  `gh pr merge <pr> --merge --delete-branch`. The issue closes through `Closes #<n>`; remove
  `agent` and the review label from the issue if they stay.
  If branch protection requires a human approval, stop at this point and ask for it in a comment.
- **Not approved after round 3**: do not start round 4. Add `review: needs human`, keep
  `status: in review`, and post a summary comment: what the PR does, the fixes made per round,
  the open required fixes with your position on each, and what a human must decide: one
  numbered question per decision, each with your recommended answer and worded so „tak”
  accepts it. Then stop.

## Rules

- One PR per issue; keep the diff to what the issue asks for.
- Never silence a check to get green; an exception follows the meritum-architecture skill
  (inline ignore with a reason).
- Never merge with failing CI or with an unresolved required fix.
- Never add e2e or cross-component tests to a CI workflow (meritum-architecture, "Tests in CI").
