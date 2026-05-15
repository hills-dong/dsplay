#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

bash scripts/build.sh

# swift-bundler v2.x writes to .build/bundler/DSPlay.app; older versions used
# build/. Probe each candidate directory independently — BSD `find` exits 1
# when given a missing path, which would otherwise trip `set -e`.
APP_PATH=""
for candidate in .build/bundler build; do
  [ -d "$candidate" ] || continue
  found="$(find "$candidate" -maxdepth 4 -name 'DSPlay.app' -type d 2>/dev/null | head -1 || true)"
  if [ -n "$found" ]; then
    APP_PATH="$found"
    break
  fi
done

if [ -z "$APP_PATH" ]; then
  echo "run.sh: could not locate DSPlay.app under .build/bundler or build/" >&2
  exit 1
fi
echo "run.sh: opening $APP_PATH"
open "$APP_PATH"
