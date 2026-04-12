#!/usr/bin/env bash
# publish-if-new.sh — pack-then-publish wrapper for the publish workflow.
#
# Tolerates ONLY "version already published" errors so reruns after a
# partial failure still succeed. Every other error (ENEEDAUTH, network,
# etc) fails loud. See issue #51 for the v0.3.1 / v0.3.2 silent-failure
# post-mortem that motivated this wrapper.
#
# Usage:
#   .github/scripts/publish-if-new.sh <package-label>
#
# Must be run from the package's working directory (where bun pm pack
# will produce the .tgz). The <package-label> is used only for log
# annotations (e.g. "@aictrl/util").

set -euo pipefail

label="${1:?Usage: publish-if-new.sh <package-label>}"

# Clean stale tarballs so we always publish the freshly packed one.
rm -f *.tgz

bun pm pack

# Use nullglob array to avoid pipefail exit on no matches (ls *.tgz
# returns exit 2 when nothing matches, which pipefail propagates).
shopt -s nullglob
tarballs=(*.tgz)
shopt -u nullglob

if [ ${#tarballs[@]} -eq 0 ]; then
  echo "::error::bun pm pack produced no .tgz files in $(pwd)"
  exit 1
fi

if [ ${#tarballs[@]} -gt 1 ]; then
  echo "::warning::bun pm pack produced ${#tarballs[@]} .tgz files in $(pwd), publishing first: ${tarballs[0]}"
fi

tarball="${tarballs[0]}"

set +e
output=$(npm publish "$tarball" --access public --provenance 2>&1)
code=$?
set -e

echo "$output"

if [ $code -ne 0 ]; then
  if echo "$output" | grep -qE 'EPUBLISHCONFLICT|E409|cannot publish over|already published'; then
    echo "::notice::Tolerating 'already published' error for ${label}"
  else
    exit $code
  fi
fi
