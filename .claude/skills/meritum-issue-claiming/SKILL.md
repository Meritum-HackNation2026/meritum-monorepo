---
name: meritum-issue-claiming
description: Use when an agent or subagent picks, starts, builds, pauses, hands off, blocks or stops work on a Meritum GitHub issue. Declares ownership with labels, assignee and a comment so parallel agents never work on the same issue, and covers branch naming, test-first building and releasing a claim.
---

# Claiming Meritum issues

Many agents work in parallel, usually from the **same GitHub account**. The assignee therefore
does not tell agents apart; the claim **comment** with your agent name does. The issue is the
lock: claim before writing code, update it when you stop. Needs `gh` (authenticated) and `jq`.

Set these once per session:

```bash
REPO=Meritum-HackNation2026/meritum-core      # the issue's repo
N=12                                         # issue number
AGENT="claude/worker-evidence-1"              # unique among parallel workers: tool/role-topic-index
```

## 1. Pick an issue

```bash
gh issue list -R "$REPO" --label "status: ready" --search "no:assignee -label:\"status: in progress\"" \
  --json number,title,labels --jq '.[] | "\(.number)\t\(.title)"'
```

Take one whose dependencies (`Depends on …` lines in Notes) are closed. Skip it if any of these is
true: it has an assignee, `status: in progress`, `status: in review`, `status: blocked` or
`status: triage`, or it is closed. If you were dispatched to a specific issue that is not free,
report back instead of starting.

## 2. Claim (one edit, then one comment)

```bash
BRANCH="feat/$N-<slug>"     # <type>/<issue-number>-<slug>; type: feat | fix | chore | docs
gh issue edit "$N" -R "$REPO" --add-assignee @me \
  --add-label "status: in progress" --add-label agent --remove-label "status: ready"
gh issue comment "$N" -R "$REPO" --body "Claimed by $AGENT, branch $BRANCH.
Plan: <one line>
Seams: <public interfaces the tests will hit>"
```

Slug: 2 to 5 lowercase ASCII words from the title, joined with `-` (`feat/12-verdict-strength-rule`).
Bugs use `fix/`, matching the conventional-commit type.

Seams are where `mattpocock-skills:tdd` puts tests: the behave steps of the issue's Gherkin and
the public API of the touched domain (`__init__.py` / `index.ts`, an endpoint, a component's
props). Naming them in the claim is the agreement tdd asks for; start without waiting for a reply.

## 3. Re-check for a race (always)

Wait about 5 s, then list claim and release comments in order:

```bash
gh api "repos/$REPO/issues/$N/comments" --paginate \
  --jq '[.[] | select(.body | test("^(Claimed by|Released by) ")) | {at: .created_at, body: .body}]'
```

Find the last `Released by` comment; among `Claimed by` comments after it, **the earliest wins**.
If it is not yours, back off: post `Released by $AGENT: lost the claim race to <winner>.`, do
not touch the labels (the winner owns them) and pick another issue.

## 4. Work

```bash
BASE=main   # develop in meritum-backend, meritum-worker, meritum-frontend; main everywhere else
git -C <repo> switch "$BASE" && git -C <repo> pull --ff-only
git -C <repo> worktree add ../<repo>-$N -b "$BRANCH" "$BASE"     # one worktree per parallel agent
```

Build with `mattpocock-skills:tdd`, in vertical slices at the claimed seams: the behave scenario
goes red first, then one unit test and one minimal change per cycle until the scenario is green.
A `bug:` issue, or a failure you cannot explain, goes through `mattpocock-skills:diagnosing-bugs`
first: its red feedback loop becomes the regression test, and the confirmed hypothesis goes into
the commit message. Feedback loops that need running services stay local scripts, out of CI.

Comment only for things the issue author must know: a decision, a scope change, a blocker.
No "still working" comments.

## 5. Blocked

```bash
gh issue edit "$N" -R "$REPO" --add-label "status: blocked" --remove-label "status: in progress"
gh issue comment "$N" -R "$REPO" --body "Blocked ($AGENT): <reason>. Needs: <who or which issue>. Branch: $BRANCH."
```

Keep the assignee while you wait; release (step 7) if you stop waiting. When the blocker is a
step only a human can do (a cloud console, a secret, a Discord app), invoke
`mattpocock-skills:wizard` for a script that walks them through it, push it on the branch and
name its path in the comment.

## 6. Hand off to review

When the PR is open, follow **meritum-pr-review-loop**. It sets `status: in review`, removes
`status: in progress` and keeps `agent` until merge.

## 7. Release when stopping without a PR

```bash
gh issue edit "$N" -R "$REPO" --remove-assignee @me --remove-label agent \
  --remove-label "status: in progress" --add-label "status: ready"     # or keep status: blocked
gh issue comment "$N" -R "$REPO" --body "Released by $AGENT: <why>. Done: <what>. Left: <what>. Branch: $BRANCH (pushed / not pushed)."
```

Never leave an issue in `status: in progress` when you stop, including when interrupted: push
the branch first so the next agent can continue.

## Stale claims

A claim with no commit, comment or PR activity for 24 h may be taken over: comment
`Taking over from <agent>: no activity since <date>.`, then claim as in step 2.
