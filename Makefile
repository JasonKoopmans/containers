# Local helpers. These mirror what CI does, for building/testing before you push.
#
#   make build C=example    # build the image locally
#   make run   C=example    # build + run it
#   make new   C=my-tool    # scaffold a new container folder
#
# OWNER defaults to your lowercased git user name; override on the command line
# (e.g. `make build C=example OWNER=jkoopmans`) to match your GitHub username.

REGISTRY ?= ghcr.io
OWNER    ?= $(shell git config user.name 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

.PHONY: build run new list

build:
	@test -n "$(C)" || { echo "Usage: make build C=<container-folder>"; exit 1; }
	docker build \
		-t $(REGISTRY)/$(OWNER)/$(C):$$(tr -d '[:space:]' < $(C)/VERSION) \
		-t $(REGISTRY)/$(OWNER)/$(C):latest \
		./$(C)

run: build
	docker run --rm -it $(REGISTRY)/$(OWNER)/$(C):latest

new:
	@test -n "$(C)" || { echo "Usage: make new C=<container-folder>"; exit 1; }
	./scripts/new-container.sh $(C)

list:
	@git ls-files '*/Dockerfile' | sed 's:/Dockerfile$$::' | sort -u
