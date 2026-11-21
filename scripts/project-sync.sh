#!/usr/bin/env bash
# Adds every issue (open and closed) from the org repos to the org project "Meritum" and fills
# Priorytet and Rozmiar from the `priority: ...` and `size: ...` labels. Status comes from the
# `status: ...` label (closed issues: Zrobione) only while nobody has set it: Status is empty, or
# still the Backlog that the "Item added to project" workflow put on an item added under 2 hours ago.
# Promotes unblocked work: an open `status: triage` + `priority: mvp` issue (not `type: epic`) whose
# blocked_by dependencies are all closed gets `status: ready` instead of `status: triage`, and its
# Status goes from Backlog (or empty) to "Gotowe do pracy".
# Idempotent; run by .github/workflows/project-sync.yml every 15 minutes.
#
# Usage: GH_TOKEN=... scripts/project-sync.sh
# Needs: uv; a token with org Projects read/write, Issues read/write and Metadata read on all org
# repos. With read-only Issues the label swap is skipped with a warning; the rest still runs.
set -euo pipefail
exec uv run --quiet --no-project python - "$@" <<'PY'
import json, os, urllib.error, urllib.parse, urllib.request
from datetime import datetime, timedelta, timezone

ORG, PROJECT_NUMBER = "Meritum-HackNation2026", 1
TOKEN = os.environ.get("GH_TOKEN") or os.environ["GITHUB_TOKEN"]
PRIORITY = {"priority: mvp": "MVP", "priority: if time": "Jeśli starczy czasu",
            "priority: after hackathon": "Po hackathonie"}
SIZE = {"size: S": "S", "size: M": "M", "size: L": "L"}
STATUS = {"status: triage": "Backlog", "status: ready": "Gotowe do pracy",
          "status: in progress": "W toku", "status: in review": "W przeglądzie",
          "status: blocked": "Zablokowane"}
FRESH = timedelta(hours=2)  # longer than the cron interval, so a missed run still catches up


def gql(query: str, **variables):
    req = urllib.request.Request(
        "https://api.github.com/graphql",
        data=json.dumps({"query": query, "variables": variables}).encode(),
        headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        body = json.load(resp)
    if body.get("errors"):
        raise SystemExit(f"GraphQL error: {body['errors']}")
    return body["data"]


def rest(method: str, path: str, body=None):
    req = urllib.request.Request(
        f"https://api.github.com/{path}", method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {TOKEN}", "Accept": "application/vnd.github+json",
                 "X-GitHub-Api-Version": "2022-11-28"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def pages(query: str, path: list[str], **variables):
    after = None
    while True:
        node = gql(query, after=after, **variables)
        for key in path:
            node = node[key]
        yield from node["nodes"]
        if not node["pageInfo"]["hasNextPage"]:
            return
        after = node["pageInfo"]["endCursor"]


def pick(labels: list[str], mapping: dict[str, str]) -> str | None:
    return next((mapping[name] for name in labels if name in mapping), None)


def wanted_status(labels: list[str], closed: bool) -> str | None:
    return "Zrobione" if closed else pick(labels, STATUS)


def promotable(labels: list[str], closed: bool) -> bool:
    return not closed and {"status: triage", "priority: mvp"} <= set(labels) and "type: epic" not in labels


def promote(repo: str, number: int) -> bool:
    """Swaps status: triage for status: ready when no blocked_by dependency is still open."""
    issue_path = f"repos/{ORG}/{repo}/issues/{number}"
    blockers = rest("GET", f"{issue_path}/dependencies/blocked_by?per_page=100")
    if any(b["state"] == "open" for b in blockers):
        return False
    try:
        rest("POST", f"{issue_path}/labels", {"labels": ["status: ready"]})
    except urllib.error.HTTPError as err:
        if err.code != 403:
            raise
        print(f"warning: {repo}#{number} is unblocked, but the token cannot edit labels (Issues: read-only)")
        return False
    rest("DELETE", f"{issue_path}/labels/{urllib.parse.quote('status: triage', safe='')}")
    print(f"promoted {repo}#{number} to status: ready")
    return True


def status_is_free(item: dict | None, now: datetime) -> bool:
    """True while no person has set Status: empty, or the add workflow's fresh Backlog."""
    if item is None or not item["status"]:
        return True
    created = datetime.fromisoformat(item["createdAt"].replace("Z", "+00:00"))
    return item["status"]["name"] == "Backlog" and now - created < FRESH


now = datetime.now(timezone.utc)
assert wanted_status(["status: ready", "size: S"], False) == "Gotowe do pracy"
assert wanted_status(["status: ready"], True) == "Zrobione"
assert pick(["type: bug"], PRIORITY) is None
assert promotable(["status: triage", "priority: mvp", "type: feature"], False)
assert not promotable(["status: triage", "priority: mvp", "type: epic"], False)
assert not promotable(["status: triage", "priority: mvp"], True)
assert not promotable(["status: triage", "priority: if time"], False)
assert not status_is_free({"status": {"name": "W toku"}, "createdAt": now.isoformat()}, now)
assert status_is_free({"status": {"name": "Backlog"}, "createdAt": now.isoformat()}, now)

project = gql(
    """query($org:String!,$num:Int!){organization(login:$org){projectV2(number:$num){id
         fields(first:50){nodes{... on ProjectV2SingleSelectField{id name options{id name}}}}}}}""",
    org=ORG, num=PROJECT_NUMBER,
)["organization"]["projectV2"]
fields = {f["name"]: f for f in project["fields"]["nodes"] if f}

items = {
    i["content"]["id"]: i
    for i in pages(
        """query($org:String!,$num:Int!,$after:String){organization(login:$org){projectV2(number:$num){
             items(first:100,after:$after){pageInfo{hasNextPage endCursor} nodes{id createdAt
               content{... on Issue{id} ... on PullRequest{id}}
               status:fieldValueByName(name:"Status"){... on ProjectV2ItemFieldSingleSelectValue{name}}
               prio:fieldValueByName(name:"Priorytet"){... on ProjectV2ItemFieldSingleSelectValue{name}}
               size:fieldValueByName(name:"Rozmiar"){... on ProjectV2ItemFieldSingleSelectValue{name}}}}}}}""",
        ["organization", "projectV2", "items"], org=ORG, num=PROJECT_NUMBER,
    )
    if i["content"]  # drafts and inaccessible items have no content
}


def set_field(item_id: str, field: str, value: str) -> None:
    option = next(o["id"] for o in fields[field]["options"] if o["name"] == value)
    gql("""mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){updateProjectV2ItemFieldValue(input:{
           projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){projectV2Item{id}}}""",
        p=project["id"], i=item_id, f=fields[field]["id"], o=option)


repos = [r["name"] for r in pages(
    """query($org:String!,$after:String){organization(login:$org){
         repositories(first:100,after:$after,isArchived:false){pageInfo{hasNextPage endCursor} nodes{name}}}}""",
    ["organization", "repositories"], org=ORG,
)]
total = added = updated = promoted = 0
for repo in repos:
    for issue in pages(
        """query($org:String!,$repo:String!,$after:String){repository(owner:$org,name:$repo){
             issues(first:100,after:$after){pageInfo{hasNextPage endCursor}
               nodes{id number state labels(first:50){nodes{name}}}}}}""",
        ["repository", "issues"], org=ORG, repo=repo,
    ):
        total += 1
        item = items.get(issue["id"])
        if item is None:
            item_id = gql("""mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){
                             item{id}}}""", p=project["id"], c=issue["id"])["addProjectV2ItemById"]["item"]["id"]
            added += 1
        else:
            item_id = item["id"]
        labels = [label["name"] for label in issue["labels"]["nodes"]]
        closed = issue["state"] == "CLOSED"
        current = item or {"status": None, "prio": None, "size": None}
        changes = {
            "Priorytet": (pick(labels, PRIORITY), current["prio"]),
            "Rozmiar": (pick(labels, SIZE), current["size"]),
        }
        if status_is_free(item, now):
            changes["Status"] = (wanted_status(labels, closed), current["status"])
        if promotable(labels, closed) and promote(repo, issue["number"]):
            promoted += 1
            if (current["status"] or {}).get("name") in (None, "Backlog"):
                changes["Status"] = ("Gotowe do pracy", current["status"])
        for field, (want, have) in changes.items():
            if want and want != (have or {}).get("name"):
                set_field(item_id, field, want)
                updated += 1
print(f"{len(repos)} repos, {total} issues, {added} added, {updated} field values set, {promoted} promoted")
PY
