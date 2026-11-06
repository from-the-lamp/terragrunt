FROM alpine:3.24.4

# python3 from apk, not mise: mise's python core plugin has no prebuilt
# binary for musl, so on Alpine `mise install` falls back to compiling
# CPython from source (python-build) - needs a full build toolchain
# (patch, gcc, zlib-dev, openssl-dev, ...) for a script that's stdlib-only
# (.docker/changed_units.py) and gains nothing from the exact pinned
# version. apk's python3 is enough; mise below installs every other
# mise.toml tool except python by naming them explicitly.
RUN apk add --no-cache curl git jq bash python3
RUN curl -fsSL https://mise.run | sh
ENV PATH="/root/.local/bin:/root/.local/share/mise/shims:${PATH}"

WORKDIR /mise
COPY mise.toml ./
# mise.toml's postinstall hook bootstraps .env for a human's first local
# clone - meaningless here (this WORKDIR isn't a real checkout) and would
# fail outright (.env.example isn't copied in above). CI=true makes the
# hook skip itself entirely instead of papering over it with a dummy .env.
ENV CI=true
RUN mise trust && mise install task opentofu terragrunt kubectl talosctl jq oras vault
