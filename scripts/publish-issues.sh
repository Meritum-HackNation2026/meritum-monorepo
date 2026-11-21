#!/usr/bin/env bash
# Files the drafts from issues/drafts/ as GitHub issues, in dependency order, idempotent by title.
# Epics (issues/drafts/epics/) go to meritum-monorepo first, in the order of their own depends_on;
# every child is linked to its epic as a sub-issue (best effort). depends_on becomes "Depends on <url>"
# lines in Notes and, where the issue dependencies API answers, "blocked by" relationships.
# relates_to becomes a "Powiązane:" line in Notes. Epic bodies are rewritten at the end with a task
# list of their children; draft IDs in epic bodies and "Powiązane:" lines become links.
#
# Usage: scripts/publish-issues.sh [--dry-run] [draft-id ...]   e.g. core/006 worker/001
# Needs: gh (authenticated, repo scope), uv. Run scripts/setup-labels.sh first: every label must be
# defined there, which the script checks before anything else (also in --dry-run).
set -euo pipefail
cd "$(dirname "$0")/.."
exec uv run --quiet --no-project --with pyyaml python - "$@" <<'PY'
import json, re, subprocess, sys, tempfile, time
from pathlib import Path

import yaml

ORG = "Meritum-HackNation2026"
EPIC_REPO = "meritum-monorepo"
ROOT = Path("issues/drafts")
DRY = "--dry-run" in sys.argv
ONLY = {a for a in sys.argv[1:] if not a.startswith("--")}


def load() -> dict[str, dict]:
    drafts = {}
    for path in sorted(ROOT.glob("*/*.md")):
        text = path.read_text(encoding="utf-8")
        match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
        if not match:
            sys.exit(f"{path}: missing frontmatter")
        meta = yaml.safe_load(match.group(1))
        is_epic = path.parent.name == "epics"
        draft_id = f"epics/{meta['epic']}" if is_epic else f"{path.parent.name}/{path.name[:3]}"
        drafts[draft_id] = {**meta, "id": draft_id, "body": match.group(2).strip(), "is_epic": is_epic}
    for d in drafts.values():
        for key in ("depends_on", "relates_to"):
            for dep in d.get(key) or []:
                if dep not in drafts:
                    sys.exit(f"{d['id']}: unknown {key} entry {dep}")
    return drafts


def known_labels() -> set[str]:
    """Label names defined in scripts/setup-labels.sh ("name|color|description" entries)."""
    text = Path("scripts/setup-labels.sh").read_text(encoding="utf-8")
    return set(re.findall(r'^\s*"([^"|]+)\|[0-9a-fA-F]{6}\|', text, re.M))


def check_labels(drafts: dict[str, dict]) -> None:
    labels = known_labels()
    bad = [f"{k}: {label}" for k, d in sorted(drafts.items()) for label in d["labels"] if label not in labels]
    if bad:
        sys.exit("labels missing from scripts/setup-labels.sh:\n  " + "\n  ".join(bad))


def natural(key: str) -> tuple:
    return tuple(int(p) if p.isdigit() else p for p in re.split(r"(\d+)", key))


def order(drafts: dict[str, dict]) -> list[str]:
    """Epics first, then children, each group in topological order (stable by natural id)."""
    done: list[str] = []
    for is_epic in (True, False):
        pending = sorted((k for k, d in drafts.items() if d["is_epic"] is is_epic), key=natural)
        while pending:
            ready = [k for k in pending if all(dep in done for dep in drafts[k].get("depends_on") or [])]
            if not ready:
                sys.exit(f"dependency cycle among: {', '.join(pending)}")
            done += ready
            pending = [k for k in pending if k not in ready]
    return done


def gh(*args: str) -> str:
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout.strip()


def find_by_title(repo: str, title: str) -> str | None:
    out = gh("issue", "list", "-R", f"{ORG}/{repo}", "--state", "all", "--limit", "100",
             "--search", f'"{title}" in:title', "--json", "title,url")
    return next((i["url"] for i in json.loads(out) if i["title"] == title), None)


def db_id(url: str) -> str:
    repo, number = url.split("/")[-3], url.split("/")[-1]
    return gh("api", f"repos/{ORG}/{repo}/issues/{number}", "--jq", ".id")


def best_effort(*args: str) -> None:
    result = subprocess.run(["gh", *args], capture_output=True, text=True)
    if result.returncode != 0 and "already" not in result.stderr.lower():
        print(f"  warn: gh {' '.join(args[:2])}: {result.stderr.strip()[:160]}")
    time.sleep(1)


def with_notes(body: str, lines: list[str]) -> str:
    if not lines:
        return body
    text = "\n".join(lines)
    return f"{body}\n\n{text}" if "### Notes" in body else f"{body}\n\n### Notes\n\n{text}"


def link(key: str, urls: dict[str, str]) -> str:
    return urls.get(key, f"<{key}>")


def render(d: dict, urls: dict[str, str]) -> str:
    """Body with "Powiązane:" and "Depends on" lines; draft IDs in epic bodies become links."""
    body = d["body"]
    if d["is_epic"]:
        body = re.sub(r"\b[a-z-]+/\d{3}\b", lambda m: urls.get(m.group(0), m.group(0)), body)
    lines = []
    if d.get("relates_to"):
        lines.append("Powiązane: " + ", ".join(link(k, urls) for k in d["relates_to"]))
    lines += [f"Depends on {link(k, urls)}" for k in d.get("depends_on") or []]
    return with_notes(body, lines)


def edit_body(url: str, body: str) -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as f:
        f.write(body)
    gh("issue", "edit", url, "--body-file", f.name)
    time.sleep(1)


def dependencies_api(url: str) -> bool:
    """True when the issue dependencies API answers for this repo (GET .../dependencies/blocked_by)."""
    repo, number = url.split("/")[-3], url.split("/")[-1]
    probe = subprocess.run(["gh", "api", f"repos/{ORG}/{repo}/issues/{number}/dependencies/blocked_by"],
                           capture_output=True, text=True)
    return probe.returncode == 0


def create(repo: str, title: str, labels: list[str], body: str) -> str:
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as f:
        f.write(body)
    args = ["issue", "create", "-R", f"{ORG}/{repo}", "--title", title, "--body-file", f.name]
    for label in labels:
        args += ["--label", label]
    url = gh(*args)
    time.sleep(1)
    return url


drafts = load()
check_labels(drafts)
plan = [k for k in order(drafts) if not ONLY or k in ONLY or drafts[k]["is_epic"]]
urls: dict[str, str] = {}
children: dict[str, list[str]] = {}
created: list[str] = []
blocked_by_api: dict[str, bool] = {}
for key in plan:
    d = drafts[key]
    if DRY:
        after = f"  [after {', '.join(d['depends_on'])}]" if d.get("depends_on") else ""
        print(f"{key:20} {d['repo']:22} {d['title']}{after}")
        urls[key] = f"<{key}>"
        continue
    url = find_by_title(d["repo"], d["title"])
    if url:
        print(f"exists   {key:20} {url}")
    else:
        url = create(d["repo"], d["title"], d["labels"], render(d, urls))
        created.append(key)
        print(f"created  {key:20} {url}")
        if d["repo"] not in blocked_by_api:
            blocked_by_api[d["repo"]] = dependencies_api(url)
            if not blocked_by_api[d["repo"]]:
                print(f"  note: no issue dependencies API in {d['repo']}; \"Depends on\" lines only")
        for dep in d.get("depends_on") or []:
            if dep in urls and blocked_by_api[d["repo"]]:
                number = url.rsplit("/", 1)[1]
                best_effort("api", f"repos/{ORG}/{d['repo']}/issues/{number}/dependencies/blocked_by",
                            "-F", f"issue_id={db_id(urls[dep])}")
        epic_url = urls.get(f"epics/{d.get('epic')}")
        if epic_url and not d["is_epic"]:
            best_effort("api", f"repos/{ORG}/{EPIC_REPO}/issues/{epic_url.rsplit('/', 1)[1]}/sub_issues",
                        "-F", f"sub_issue_id={db_id(url)}")
    urls[key] = url
    if not d["is_epic"]:
        children.setdefault(f"epics/{d.get('epic')}", []).append(f"- [ ] {url} {d['title']}")

if DRY:
    print(f"\n{len(plan)} drafts, labels ok, no dependency cycle")
else:
    for key, d in drafts.items():
        if d["is_epic"] and key in urls and children.get(key):
            body = render(d, urls).replace("<!-- children -->", "\n".join(children[key]))
            edit_body(urls[key], body)
            print(f"updated  {key:20} task list ({len(children[key])} children)")
    # issues created before their relates_to targets existed: fill in the links now
    for key in created:
        d = drafts[key]
        if not d["is_epic"] and any(r in created and plan.index(r) > plan.index(key) for r in d.get("relates_to") or []):
            edit_body(urls[key], render(d, urls))
            print(f"updated  {key:20} related links")
PY
