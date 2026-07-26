#!/bin/bash
# Deploy a working copy straight into the live AddOns folder for testing.
# Override the target with DFUI_ADDONS_DIR, e.g.
#   DFUI_ADDONS_DIR="/Applications/World of Warcraft/_classic_/Interface/AddOns" ./scripts/deploy.sh
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
ADDONS_DIR="${DFUI_ADDONS_DIR:-/Applications/World of Warcraft/_classic_era_/Interface/AddOns}"
DEST="$ADDONS_DIR/DragonflightUI"
rsync -a --delete \
    --exclude '.git' --exclude 'docs' --exclude 'scripts' --exclude 'tests' \
    --exclude '*.md' --exclude '.github' --exclude '.vscode' \
    "$SRC/" "$DEST/"
echo "Deployed to $DEST"
