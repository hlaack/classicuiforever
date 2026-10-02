"""Fill a pull request's blank description from its commits and changed files, in the template's sections.

Refreshed on later pushes while the filled text is unedited; a description a person wrote is never touched.
Usage: python pr_autofill.py OWNER/REPO NUMBER [--dry-run]
"""
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

TEMPLATE = Path(".github/pull_request_template.md")
MARK = re.compile(r"\A<!-- autofill ([0-9a-f]{12}) -->\n")
FIXES = re.compile(r"\b(?:fix(?:es|ed)?|close[sd]?|resolve[sd]?)\s+#(\d+)", re.I)
# Top folder -> the piece it holds (tools/CONVENTIONS.md folder map).
PIECES = {
    "Art": "art and themes", "Bar": "the classic bar", "Character": "the character sheet", "Core": "core",
    "Locales": "translations", "Map": "the minimap and world map", "Options": "the options",
    "Quest": "the quest log and tracker", "Skills": "professions, trainer and talents",
    "Social": "the social window and guild", "Spells": "the spellbook", "UI": "shared UI pieces",
    "Units": "the unit frames", "Windows": "client windows (chat, loot, bags, bank)", "tools": "checks and tests",
    ".github": "repo automation", ".luacheckrc": "lint settings", "ClassicUIForever.toc": "the load order",
}


def gh(*args, stdin=None):
    return subprocess.run(["gh", *args], input=stdin, check=True, capture_output=True, text=True,
                          encoding="utf-8").stdout


def items(path):
    out = gh("api", "--paginate", path, "--jq", ".[] | @json")
    return [json.loads(line) for line in out.splitlines() if line.strip()]


def words(text):
    return re.sub(r"<!--.*?-->", "", text, flags=re.S).split()


def blank(body):
    if not words(body):
        return True
    return TEMPLATE.exists() and words(body) == words(TEMPLATE.read_text(encoding="utf-8"))


def digest(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]


def build(repo, pr):
    commits = items(f"repos/{repo}/pulls/{pr}/commits")
    files = items(f"repos/{repo}/pulls/{pr}/files")
    changes, issues = [], []
    for c in commits:
        subject, _, rest = c["commit"]["message"].strip().partition("\n")
        changes.append(f"- {subject}")
        changes += [f"  {line.strip()}" for line in rest.splitlines() if line.strip()]
        issues += [n for n in FIXES.findall(c["commit"]["message"]) if n not in issues]
    pieces = []
    for f in files:
        top = f["filename"].split("/")[0] if "/" in f["filename"] else f["filename"]
        piece = PIECES.get(top, top)
        if piece not in pieces:
            pieces.append(piece)
    added = sum(f["additions"] for f in files)
    removed = sum(f["deletions"] for f in files)
    lines = ["Filled in from the commits because the description was blank; it follows new pushes until edited.", "",
             "## What this changes", "", *changes, "",
             "## Issue", "", "\n".join(f"Fixes #{n}" for n in issues) or "None named in the commits.", "",
             "## Which piece it touches", "", ", ".join(pieces), "",
             f"## Files ({len(files)}, +{added} -{removed})", "",
             *[f"- `{f['filename']}` +{f['additions']} -{f['deletions']}" for f in files], "",
             "## Tested on", "", "Not stated."]
    return "\n".join(lines) + "\n"


def main():
    repo, pr = sys.argv[1], sys.argv[2]
    dry = "--dry-run" in sys.argv[3:]
    body = gh("api", f"repos/{repo}/pulls/{pr}", "--jq", '.body // ""').replace("\r\n", "\n").rstrip()
    mark = MARK.match(body)
    ours = mark and digest(body[mark.end():]) == mark.group(1)
    if not (blank(body) or ours):
        print("description written by hand: left alone")
        return
    content = build(repo, pr)
    new = f"<!-- autofill {digest(content.rstrip())} -->\n{content}"
    if new.rstrip() == body:
        print("description already up to date")
        return
    if dry:
        print(new)
        return
    gh("api", "--method", "PATCH", f"repos/{repo}/pulls/{pr}", "--input", "-", stdin=json.dumps({"body": new}))
    print("description filled")


if __name__ == "__main__":
    main()
