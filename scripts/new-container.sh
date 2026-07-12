#!/usr/bin/env bash
# Scaffold a new container folder: Dockerfile, VERSION, DESCRIPTION, README,
# .dockerignore.
# Usage: scripts/new-container.sh <container-name>
set -euo pipefail

name="${1:-}"
if [ -z "$name" ]; then
  echo "Usage: $0 <container-name>" >&2
  exit 1
fi
if [ -e "$name" ]; then
  echo "Error: '$name' already exists" >&2
  exit 1
fi

mkdir -p "$name"

cat > "$name/Dockerfile" <<EOF
FROM alpine:3.24

LABEL org.opencontainers.image.title="$name"

CMD ["sh", "-c", "echo hello from $name"]
EOF

echo "0.1.0" > "$name/VERSION"

# One-line-ish blurb shown as the GHCR package description (index annotation).
echo "TODO: one or two sentences describing $name (shown on the GHCR package page)." > "$name/DESCRIPTION"

cat > "$name/.dockerignore" <<'EOF'
README.md
VERSION
DESCRIPTION
EOF

cat > "$name/README.md" <<EOF
# $name

Describe what this container does.

## Image

\`\`\`
ghcr.io/OWNER/$name:latest
\`\`\`

Versions are tracked in \`VERSION\` — bump it in the same commit that changes
this container. The \`DESCRIPTION\` file becomes the GHCR package description.
EOF

echo "Created ./$name (VERSION 0.1.0)."
echo "Next: edit $name/Dockerfile and $name/DESCRIPTION, add a row to the"
echo "      Containers table in README.md, then commit to main to publish."
