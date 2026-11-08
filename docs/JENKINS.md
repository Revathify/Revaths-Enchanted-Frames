# Local Jenkins

Project: http://localhost:8088/job/enchanted-frames/

- Pipeline script from SCM: Git, `https://github.com/Revathify/Revaths-Enchanted-Frames`, branch `*/main`, script `Jenkinsfile`.
- Repository polling: every two minutes while Jenkins runs. Existing GitHub authentication is used for checkout and publishing; the secret stays in Jenkins credentials.
- The controller has Python 3 and Docker access. An isolated `python:3.13-slim` build image installs the pinned Lua runtime from `scripts/ci/requirements.txt`.
- Sources are copied into a temporary build container, excluding `.git` and old artifacts. The source commit is supplied separately. Build containers are removed in the pipeline's cleanup stage, including after failure.
- All six active TOCs must have the same explicit Major.Minor.Hotfix version. A new module advances Major; features advance Minor; fixes advance Hotfix.
- Validation runs active Lua syntax checks, all `tests/*.lua` behavior tests, manifest asset checks, ZIP integrity/module/version checks, and records the artifact digest and source commit.
- The release stage binds the project's username/password GitHub credential with its token as `GH_TOKEN`. Never put tokens in the repository, script arguments, or build logs. If rotating the credential, retain its Jenkins ID or update the binding deliberately.
- `PUBLISH_RELEASE=true` publishes a new version. Public versions are skipped. A draft release is populated before publication so interrupted uploads can be retried without publishing an empty ZIP release.
- Builds and packages are archived in Jenkins. Set `PUBLISH_RELEASE=false` for review builds. Keep Jenkins/Docker running for automatic polling.

## CurseForge upload

Jenkins sends the same validated ZIP to [CurseForge project 1696169](https://authors.curseforge.com/#/projects/1696169/files) and GitHub Releases. Add a Jenkins **Secret text** credential with ID `curseforge-upload-token` using a [CurseForge author API token](https://www.curseforge.com/account/api-tokens). Jenkins maps the manifests' interface number to the matching WoW game version with the [CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321).

After the GitHub draft ZIP upload, Jenkins pushes the version tag at the validated commit, submits the ZIP to CurseForge, and records the CurseForge file ID in the draft body before publishing the draft. An upload can enter CurseForge moderation before it appears publicly. Jenkins skips public GitHub releases.

If a run leaves `<!-- curseforge-upload: pending -->` in a GitHub draft, check CurseForge Files for that version. If CurseForge accepted it, replace `pending` with the file ID. If you confirm the upload failed, remove the marker. Rerun Jenkins after reconciling the draft. Leave the GitHub package webhook inactive so CurseForge receives one ZIP per version.

Local validation: install `scripts/ci/requirements.txt` in an isolated Python environment, then run `python scripts/build.py` from the repository root. This creates `artifacts/RevathsEnchantedFrames-vVERSION.zip` and `artifacts/build.json`.
