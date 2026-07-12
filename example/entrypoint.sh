#!/bin/sh
set -e

echo "hello from the example container (version ${IMAGE_VERSION:-dev})"

# If arguments were passed to `docker run`, execute them; otherwise just exit.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi
