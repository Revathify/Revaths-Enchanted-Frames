"""Publish a tested Jenkins artifact; never replace an existing release or asset."""
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from publish_curseforge import upload_zip

REPO = "Revathify/Revaths-Enchanted-Frames"
API = f"https://api.github.com/repos/{REPO}"
GIT_REMOTE = f"https://github.com/{REPO}.git"
CURSEFORGE_RECEIPT = re.compile(r"^<!-- curseforge-upload: (pending|[1-9]\d*) -->\r?$", re.MULTILINE)

def request(url, data=None, content_type="application/json", method=None):
    headers = {"Authorization": "Bearer " + os.environ["GH_TOKEN"],
               "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28",
               "User-Agent": "EnchantedFrames-Jenkins", "Content-Type": content_type}
    req = Request(url, data=data, headers=headers, method=method)
    with urlopen(req, timeout=120) as response:
        return json.load(response)

def find_release(tag):
    try:
        return request(API + "/releases/tags/" + tag)
    except HTTPError as error:
        if error.code != 404:
            raise

    # The tag endpoint can omit drafts. Search the authenticated release list
    # for a draft with a durable upload receipt before creating another one.
    page = 1
    while True:
        releases = request(f"{API}/releases?per_page=100&page={page}")
        for release in releases:
            if release["tag_name"] == tag:
                return release
        if len(releases) < 100:
            return None
        page += 1

def push_release_tag(commit, tag):
    # GitHub ignores target_commitish when the tag already exists. A non-force
    # push verifies that this version refers to the tested commit.
    helper = '!f() { if [ "$1" = get ]; then printf "username=%s\\npassword=%s\\n" "$GH_USER" "$GH_TOKEN"; fi; }; f'
    subprocess.run(
        ["git", "-c", "credential.helper=", "-c", f"credential.helper={helper}",
         "push", "--no-follow-tags", GIT_REMOTE, f"{commit}:refs/tags/{tag}"],
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        check=True,
    )

def publish_to_curseforge(release_url, body, asset, tag):
    receipts = CURSEFORGE_RECEIPT.findall(body)
    if len(receipts) > 1:
        raise RuntimeError("The GitHub draft has multiple CurseForge markers. Reconcile them before retrying.")
    if receipts:
        if receipts[0] == "pending":
            raise RuntimeError("Check CurseForge Files and reconcile the pending marker in the GitHub draft before retrying.")
        print(f"CurseForge already accepted {tag} as file {receipts[0]}.")
        return

    def record(status):
        updated = f"{body.rstrip()}\n\n<!-- curseforge-upload: {status} -->"
        request(release_url, json.dumps({"body": updated}).encode(), method="PATCH")

    # A lost upload response is ambiguous. Persist intent before sending the ZIP
    # so a retried Jenkins run cannot submit a duplicate file.
    file_id = upload_zip(asset, tag, body, before_upload=lambda: record("pending"))
    record(file_id)
    print(f"CurseForge accepted {tag} as file {file_id}.")

def publish():
    evidence = json.loads(Path("artifacts/build.json").read_text())
    tag = "v" + evidence["version"]
    asset = Path("artifacts", f"RevathsEnchantedFrames-{tag}.zip")
    import hashlib
    assert hashlib.sha256(asset.read_bytes()).hexdigest() == evidence["sha256"], "Artifact changed after validation"
    existing = find_release(tag)
    if existing and not existing.get("draft"):
        print(f"{tag} already published; leaving it unchanged.")
        return
    if existing:
        release = existing
        assert release["target_commitish"] == evidence["commit"], "Draft targets a different commit"
    else:
        notes = Path("docs/releases", tag + ".md")
        payload = {"tag_name": tag, "target_commitish": evidence["commit"],
                   "name": f"Revath's Enchanted Frames {tag}", "draft": True,
                   "body": notes.read_text(encoding="utf-8") if notes.exists() else "Built and validated by local Jenkins."}
        release = request(API + "/releases", json.dumps(payload).encode())
    current = next((a for a in release.get("assets", []) if a["name"] == asset.name), None)
    if current:
        assert current.get("digest") == "sha256:" + evidence["sha256"], "Existing draft asset differs"
    else:
        upload = release["upload_url"].split("{")[0] + "?name=" + asset.name
        request(upload, asset.read_bytes(), "application/zip")
    release_url = API + "/releases/" + str(release["id"])
    push_release_tag(evidence["commit"], tag)
    publish_to_curseforge(release_url, release.get("body") or "", asset, tag)
    request(release_url, json.dumps({"draft": False}).encode(), method="PATCH")
    print(f"Published {tag} from validated commit {evidence['commit']}.")

if __name__ == "__main__":
    try:
        publish()
    except HTTPError as error:
        try:
            message = json.loads(error.read()).get("message", "")
        except (ValueError, UnicodeError):
            message = ""
        raise SystemExit(f"GitHub publishing failed: HTTP {error.code}. {message} Check the Jenkins credential permissions.") from None
    except (RuntimeError, ValueError) as error:
        raise SystemExit(str(error)) from None
