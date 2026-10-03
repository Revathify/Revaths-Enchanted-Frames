"""Validate and package the exact manifest version. Run from the repository root."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import zipfile

ADDONS = ("RevathsEnchantedFrames", "RevathsMailbox", "RevathsMacro",
          "RevathsMailboxTooltipHelper", "RevathsWeeklyPlanner", "RevathsWhispers")

def build():
    from lupa.lua51 import LuaRuntime
    versions = []
    sources = []
    for addon in ADDONS:
        toc = Path(addon, addon + ".toc")
        text = toc.read_text(encoding="utf-8-sig")
        version = re.search(r"^## Version:\s*(\d+\.\d+\.\d+)\s*$", text, re.M)
        if not version:
            raise ValueError(f"Missing semantic version: {toc}")
        versions.append(version.group(1))
        for line in text.splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                asset = Path(addon, line.replace("\\", "/"))
                if not asset.is_file():
                    raise ValueError(f"Missing manifest asset: {asset}")
        sources.extend(Path(addon).rglob("*.lua"))
    if len(set(versions)) != 1:
        raise ValueError(f"Unsynchronized versions: {versions}")
    for source in sources:
        LuaRuntime().execute("assert(loadstring(...))", source.read_text(encoding="utf-8-sig"))
    for test in sorted(Path("tests").glob("*.lua")):
        print(f"Testing {test}", flush=True)
        LuaRuntime().execute(test.read_text(encoding="utf-8-sig"))
    out = Path("artifacts")
    out.mkdir(exist_ok=True)
    version = versions[0]
    archive = out / f"RevathsEnchantedFrames-v{version}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as package:
        for addon in ADDONS:
            for asset in sorted(Path(addon).rglob("*")):
                if asset.is_file():
                    package.write(asset, asset.as_posix())
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None, "Corrupt archive"
        assert {name.split("/")[0] for name in package.namelist()} == set(ADDONS)
        for addon in ADDONS:
            assert f"## Version: {version}" in package.read(f"{addon}/{addon}.toc").decode("utf-8-sig")
            if addon == "RevathsWhispers":
                assert package.read(f"{addon}/Media/WhispersIcon.tga")
    commit = os.environ.get("SOURCE_COMMIT") or subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    assert re.fullmatch(r"[0-9a-f]{40}", commit), "Invalid source commit"
    evidence = {"version": version, "commit": commit, "modules": list(ADDONS),
                "lua_sources": len(sources), "tests": len(list(Path("tests").glob("*.lua"))),
                "sha256": hashlib.sha256(archive.read_bytes()).hexdigest()}
    (out / "build.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(f"Validated {len(sources)} Lua sources; packaged {archive}", flush=True)

if __name__ == "__main__":
    build()
