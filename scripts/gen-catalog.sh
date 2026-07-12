#!/usr/bin/env bash
# Regenerate the "Containers" catalog table in README.md from each container's
# DESCRIPTION file (its first non-empty line is used as the catalog blurb).
#
#   scripts/gen-catalog.sh          # rewrite the table in place
#   scripts/gen-catalog.sh --check  # exit non-zero if the table is stale (CI)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

README="README.md"
START="<!-- catalog:start -->"
END="<!-- catalog:end -->"

if ! grep -qF "$START" "$README" || ! grep -qF "$END" "$README"; then
  echo "error: catalog markers not found in $README ($START / $END)" >&2
  exit 2
fi

# GHCR namespace = repo owner, lowercased (derived from the origin remote).
OWNER="$(git remote get-url origin 2>/dev/null \
  | sed -E 's#(\.git)?$##; s#.*[/:]([^/]+)/[^/]+$#\1#' \
  | tr '[:upper:]' '[:lower:]')"
[ -n "$OWNER" ] || OWNER="jasonkoopmans"

tmp_table="$(mktemp)"
tmp_readme="$(mktemp)"
trap 'rm -f "$tmp_table" "$tmp_readme"' EXIT

{
  echo "| Image | Pull | Docs |"
  echo "| ----- | ---- | ---- |"
  for f in $(git ls-files '*/Dockerfile' | sort); do
    d="${f%%/*}"
    blurb=""
    [ -f "$d/DESCRIPTION" ] && blurb="$(grep -m1 . "$d/DESCRIPTION" | sed 's/|/\\|/g')"
    echo "| **$d** — ${blurb} | \`docker pull ghcr.io/$OWNER/$d\` | [usage →]($d/README.md) |"
  done
} > "$tmp_table"

# Replace everything between the markers with the freshly generated table.
awk -v start="$START" -v end="$END" -v tf="$tmp_table" '
  index($0, start) { print; while ((getline line < tf) > 0) print line; close(tf); skip=1; next }
  index($0, end)   { skip=0; print; next }
  skip { next }
  { print }
' "$README" > "$tmp_readme"

if [ "${1:-}" = "--check" ]; then
  if ! diff -q "$tmp_readme" "$README" >/dev/null; then
    echo "::error::README Containers table is stale — run 'make catalog' and commit." >&2
    diff "$README" "$tmp_readme" || true
    exit 1
  fi
  echo "Catalog is up to date."
else
  cp "$tmp_readme" "$README"
  echo "Regenerated Containers table in $README (owner=$OWNER)."
fi
