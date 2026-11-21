#!/usr/bin/env bash
# Files the drafts from issues/drafts/ as GitHub issues, in dependency order, idempotent by title.
# Epics (issues/drafts/epics/) go to meritum-monorepo first; every child is linked to its epic as a
# sub-issue and to its dependencies as "blocked by" (both best effort), and gets "Depends on <url>"
# lines in Notes. Epic bodies are rewritten at the end with a task list of their children.
#
# Usage: scripts/publish-issues.sh [--dry-run] [draft-id ...]   e.g. core/006 worker/001
# Needs: gh (authenticated, repo scope), uv. Run scripts/setup-labels.sh first: unknown labels fail.
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
        for dep in d.get("depends_on") or []:
            if dep not in drafts:
                sys.exit(f"{d['id']}: unknown dependency {dep}")
    return drafts


def order(drafts: dict[str, dict]) -> list[str]:
    """Epics first, then children in topological order (stable by id)."""
    done: list[str] = sorted(k for k, d in drafts.items() if d["is_epic"])
    pending = sorted(k for k, d in drafts.items() if not d["is_epic"])
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


def with_dependencies(body: str, urls: list[str]) -> str:
    if not urls:
        return body
    lines = "\n".join(f"Depends on {u}" for u in urls)
    return f"{body}\n\n{lines}" if "### Notes" in body else f"{body}\n\n### Notes\n\n{lines}"


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
plan = [k for k in order(drafts) if not ONLY or k in ONLY or drafts[k]["is_epic"]]
urls: dict[str, str] = {}
children: dict[str, list[str]] = {}
for key in plan:
    d = drafts[key]
    dep_urls = [urls.get(dep, f"<{dep}>") for dep in d.get("depends_on") or []]
    if DRY:
        print(f"{key:20} {d['repo']:22} {d['title']}" + (f"  [after {', '.join(d['depends_on'])}]" if d.get("depends_on") else ""))
        urls[key] = f"<{key}>"
        continue
    url = find_by_title(d["repo"], d["title"])
    if url:
        print(f"exists   {key:20} {url}")
    else:
        url = create(d["repo"], d["title"], d["labels"], with_dependencies(d["body"], dep_urls))
        print(f"created  {key:20} {url}")
        for dep in d.get("depends_on") or []:
            if dep in urls:
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

if not DRY:
    for key, d in drafts.items():
        if d["is_epic"] and key in urls and children.get(key):
            body = d["body"].replace("<!-- children -->", "\n".join(children[key]))
            with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as f:
                f.write(body)
            gh("issue", "edit", urls[key], "--body-file", f.name)
            print(f"updated  {key:20} task list ({len(children[key])} children)")
PY
