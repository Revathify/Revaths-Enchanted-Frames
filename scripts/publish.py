"""Publish a tested Jenkins artifact; never replace an existing release or asset."""
import json
import os
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

REPO = "Revathify/Revaths-Enchanted-Frames"
API = f"https://api.github.com/repos/{REPO}"

def request(url, data=None, content_type="application/json", method=None):
    headers = {"Authorization": "Bearer " + os.environ["GH_TOKEN"],
               "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28",
               "User-Agent": "EnchantedFrames-Jenkins", "Content-Type": content_type}
    req = Request(url, data=data, headers=headers, method=method)
    with urlopen(req, timeout=120) as response:
        return json.load(response)

def publish():
    evidence = json.loads(Path("artifacts/build.json").read_text())
    tag = "v" + evidence["version"]
    asset = Path("artifacts", f"RevathsEnchantedFrames-{tag}.zip")
    import hashlib
    assert hashlib.sha256(asset.read_bytes()).hexdigest() == evidence["sha256"], "Artifact changed after validation"
    try:
        existing = request(API + "/releases/tags/" + tag)
    except HTTPError as error:
        if error.code != 404:
            raise RuntimeError(f"Cannot check release: HTTP {error.code}") from None
        existing = None
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
    request(API + "/releases/" + str(release["id"]), json.dumps({"draft": False}).encode(), method="PATCH")
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
