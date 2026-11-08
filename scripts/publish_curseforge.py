"""Upload a validated suite ZIP to CurseForge."""
from collections.abc import Callable
import json
import os
import re
import uuid
import zipfile
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, Request, build_opener

from build import ADDONS

PROJECT_ID = 1696169
VERSIONS_URL = "https://wow.curseforge.com/api/game/versions"
UPLOAD_URL = f"https://wow.curseforge.com/api/projects/{PROJECT_ID}/upload-file"


class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def _request(url, token, data=None, content_type="application/json"):
    request = Request(
        url,
        data=data,
        headers={
            "X-Api-Token": token,
            "Accept": "application/json",
            "Content-Type": content_type,
        },
    )
    try:
        with build_opener(_NoRedirect).open(request, timeout=60) as response:
            return response.read()
    except HTTPError as error:
        raise RuntimeError(f"CurseForge request failed with HTTP {error.code}") from None
    except URLError:
        raise RuntimeError("CurseForge request failed before receiving a response") from None


def _interface_version(asset):
    versions = set()
    with zipfile.ZipFile(asset) as archive:
        names = set(archive.namelist())
        for addon in ADDONS:
            toc_name = f"{addon}/{addon}.toc"
            if toc_name not in names:
                raise ValueError(f"ZIP is missing active addon manifest {toc_name}")
            text = archive.read(toc_name).decode("utf-8-sig")
            matches = re.findall(r"^## Interface:\s*(\d+)\s*$", text, re.MULTILINE)
            if len(matches) != 1:
                raise ValueError(f"{toc_name} must contain exactly one Interface version")
            versions.add(matches[0])
    if len(versions) != 1:
        raise ValueError("Active addon manifests do not share one Interface version")
    return versions.pop()


def _game_version_id(token, interface):
    try:
        payload = json.loads(_request(VERSIONS_URL, token))
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise RuntimeError("CurseForge returned invalid game version data") from None
    records = payload.get("data") if isinstance(payload, dict) else payload
    if not isinstance(records, list):
        raise RuntimeError("CurseForge returned an unexpected game version list")
    matches = [
        record for record in records
        if isinstance(record, dict) and str(record.get("apiVersion")) == interface
    ]
    if len(matches) != 1:
        raise RuntimeError("Could not find one exact CurseForge API version match")
    version_id = matches[0].get("id")
    if not isinstance(version_id, int) or isinstance(version_id, bool) or version_id <= 0:
        raise RuntimeError("CurseForge API version has an invalid ID")
    return version_id


def _multipart(asset, tag, changelog, game_version_id):
    boundary = "----EnchantedFrames" + uuid.uuid4().hex
    metadata = {
        "changelog": changelog,
        "changelogType": "markdown",
        "displayName": f"Revath's Enchanted Frames {tag}",
        "gameVersions": [game_version_id],
        "releaseType": "release",
    }
    filename = asset.name
    chunks = [
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"metadata\"\r\n\r\n".encode("utf-8"),
        json.dumps(metadata, separators=(",", ":")).encode("utf-8"),
        f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; "
        f"filename=\"{filename}\"\r\nContent-Type: application/zip\r\n\r\n".encode("utf-8"),
        asset.read_bytes(),
        f"\r\n--{boundary}--\r\n".encode("ascii"),
    ]
    return boundary, b"".join(chunks)


def upload_zip(asset: Path, tag: str, changelog: str, *, before_upload: Callable[[], None]) -> int:
    token = os.environ.get("CURSEFORGE_API_TOKEN")
    if not token:
        raise RuntimeError("CURSEFORGE_API_TOKEN is required")
    interface = _interface_version(asset)
    game_version_id = _game_version_id(token, interface)
    boundary, body = _multipart(asset, tag, changelog, game_version_id)
    before_upload()
    try:
        payload = json.loads(_request(
            UPLOAD_URL, token, body, f"multipart/form-data; boundary={boundary}"
        ))
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise RuntimeError("CurseForge returned an invalid upload response") from None
    if not isinstance(payload, dict):
        raise RuntimeError("CurseForge returned an unexpected upload response")
    file_id = payload.get("id")
    if not isinstance(file_id, int) or isinstance(file_id, bool) or file_id <= 0:
        raise RuntimeError("CurseForge returned an invalid uploaded file ID")
    return file_id
