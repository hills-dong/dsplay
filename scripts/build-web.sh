#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT/web"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [ ! -d node_modules ]; then
  echo "build-web.sh: installing JS deps"
  pnpm install --frozen-lockfile
fi

echo "build-web.sh: building UI"
pnpm build
