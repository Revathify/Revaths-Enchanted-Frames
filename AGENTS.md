# Project guidance

Before adding or changing WoW fonts, font discovery, or symbol-based controls, read [docs/WOW-FONTS.md](docs/WOW-FONTS.md). Use the shared font resolver, validate optional fonts in the client, retain a native UI font fallback, and avoid relying on Unicode arrows for controls. These findings are retained at the user's request.

For release numbering, follow the Major.Minor.Hotfix policy in README.md. Keep all six active addon manifests synchronized and choose versions explicitly. CI, packaging, and publishing belong in Jenkinsfile and scripts; do not restore GitHub Actions workflows.
