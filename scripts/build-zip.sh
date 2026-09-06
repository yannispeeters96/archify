#!/usr/bin/env bash
# Build the distributable skill archive from the archify/ folder.
# Usage: scripts/build-zip.sh [output.zip]
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$repo_root/archify.zip}"
if [[ "$out" != /* ]]; then
  out="$(pwd)/$out"
fi

# Stage a clean copy: node_modules never ships; test/ is repo-only (the golden
# harness compares against ../examples at the repo root, which does not exist
# in an installed skill); local agent coordination folders are also excluded so
# a developer's working tree cannot leak into the distributable archive. The npm
# scripts and dependency metadata are stripped from the shipped package.json.
# Runtime schema validation is provided by the committed standalone validators,
# so installing the skill never requires npm install.
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
node "$repo_root/scripts/stage-package.mjs" "$stage/archify"

rm -f "$out"
(cd "$stage" && zip -r -X -q "$out" archify)

unzip -l "$out" | tail -1
echo "built $out"
