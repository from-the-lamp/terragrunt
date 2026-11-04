FROM alpine:3.24.3

# gcompat: mise's python core plugin ships prebuilt glibc binaries
# (python-build-standalone, "...-unknown-linux-gnu...") - Alpine is musl, so
# the interpreter would fail to even start without this. Not needed for any
# of the other mise.toml tools (all static Go/Rust binaries). UNVERIFIED -
# no docker available in the environment this was written in to build and
# actually run `python3 .docker/changed_units.py` inside the image; confirm
# with a real `task tools` build before relying on it.
RUN apk add --no-cache curl git jq bash gcompat
RUN curl -fsSL https://mise.run | sh
ENV PATH="/root/.local/bin:/root/.local/share/mise/shims:${PATH}"

WORKDIR /mise
COPY mise.toml ./
# mise.toml's postinstall hook bootstraps .env for a human's first local
# clone - meaningless here (this WORKDIR isn't a real checkout) and would
# fail outright (.env.example isn't copied in above). CI=true makes the
# hook skip itself entirely instead of papering over it with a dummy .env.
ENV CI=true
RUN mise trust && mise install
