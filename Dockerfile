# Multi-stage build for heidrun-spirit (the MegaHAL Hotline chatbot).
#
# Build from this repo's root. The build needs a GitHub token with read
# access to the private `heidrun-protocol` package — `gh auth token`
# emits one if you've run `gh auth login`:
#
#   DOCKER_BUILDKIT=1 GH_TOKEN="$(gh auth token)" \
#     docker build --secret id=gh_token,env=GH_TOKEN -t heidrun-spirit .
#
# The token is passed as a BuildKit secret, used only inside the single
# build RUN via a temporary git `insteadOf` rewrite, and never written
# to any image layer.
#
# Run (the bot connects OUT to a Hotline server — no published ports):
#   docker run -d --name heidrun-spirit \
#     -e HEIDRUN_SPIRIT_HOST=your.server.example \
#     -v spirit-brain:/var/lib/heidrun-spirit \
#     heidrun-spirit
#
# The MegaHAL brain (which the bot writes back as it learns) lives in
# the named volume at /var/lib/heidrun-spirit; it is seeded from the
# bundled training data on first run.

# syntax=docker/dockerfile:1.6

# ──────────────────────────────────────────────────────────────────────────────
# Build stage
# ──────────────────────────────────────────────────────────────────────────────
FROM swift:6.2-jammy AS build

# git + ca-certificates let SPM clone the private heidrun-protocol dep
# over HTTPS. No libsqlite3-dev — unlike heidrun-server the bot has no
# GRDB. The CMegaHAL C target compiles with the Swift image's bundled
# clang using the flags already declared in Package.swift.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Tests/ is required even though we only build the executable product:
# SPM parses the .testTarget declaration during package-graph resolution
# and fails with "overlapping sources" if Tests/ isn't present.
COPY Package.swift Package.resolved ./
COPY Sources ./Sources
COPY Tests ./Tests

# Single RUN: auth setup + build share one layer. The token is written
# to a temporary /root/.gitconfig entry, then --remove-section'd before
# the layer commits. Three insteadOf rewrites cover HTTPS plus both SSH
# URL shapes so the SSH dep URL in Package.swift resolves through the
# authed HTTPS endpoint. If RUN fails before cleanup, the layer is
# discarded entirely — the token has no path into the final image.
#
# After build, stage the binary AND its resource bundle into /out.
# Bundle.module locates the MegaHAL seed brain in SpiritKit's resource
# bundle, which SwiftPM places next to the executable — so it must travel
# with the binary. The bundle's filename is NOT hardcoded: SwiftPM
# sanitizes the package name differently across platforms (the hyphen in
# "heidrun-spirit" survives on macOS but not always on Linux), so we glob
# *.bundle, which preserves whatever name the accessor expects. Staging in
# /out keeps the runtime COPY a single, name-agnostic directory copy.
RUN --mount=type=secret,id=gh_token,required=true \
    --mount=type=cache,target=/root/.cache/org.swift.swiftpm \
    --mount=type=cache,target=/src/.build \
    GH_TOKEN="$(cat /run/secrets/gh_token)" \
 && AUTHED_BASE="https://x-access-token:${GH_TOKEN}@github.com/" \
 && git config --global "url.${AUTHED_BASE}.insteadOf" "https://github.com/" \
 && git config --global --add "url.${AUTHED_BASE}.insteadOf" "git@github.com:" \
 && git config --global --add "url.${AUTHED_BASE}.insteadOf" "ssh://git@github.com/" \
 && swift build \
      --configuration release \
      --product heidrun-spirit \
 && echo "=== .build/release contents ===" \
 && ls -la .build/release/ \
 && mkdir -p /out \
 && install -m 0755 \
      .build/release/heidrun-spirit \
      /out/heidrun-spirit \
 && find .build/release/ -maxdepth 1 \( -name '*.bundle' -o -name '*.resources' \) -print -exec cp -R {} /out/ \; \
 && echo "=== /out contents ===" \
 && ls -la /out/ \
 && git config --global --remove-section "url.${AUTHED_BASE}"

# ──────────────────────────────────────────────────────────────────────────────
# Runtime stage
# ──────────────────────────────────────────────────────────────────────────────
FROM swift:6.2-jammy-slim AS runtime

# A non-root account owns the brain directory. /var/lib/heidrun-spirit
# itself must be spirit-owned so a fresh named volume mounted there
# inherits writable permissions — MegaHAL writes the brain back as it
# learns. No extra apt packages: the bot has no SQLite, and SwiftNIO is
# pure Swift.
RUN useradd --system --home-dir /var/lib/heidrun-spirit --shell /usr/sbin/nologin spirit \
 && install -d -o spirit -g spirit /var/lib/heidrun-spirit

# Copy the staged binary + its resource bundle(s) in one shot. Copying the
# /out directory's contents preserves the .bundle directory name that
# Bundle.module expects, without the Dockerfile having to name it.
COPY --from=build /out/ /usr/local/bin/

USER spirit
WORKDIR /var/lib/heidrun-spirit

ENV HEIDRUN_SPIRIT_BRAIN_PATH=/var/lib/heidrun-spirit/brain \
    HEIDRUN_SPIRIT_LOG_LEVEL=info

# No EXPOSE — heidrun-spirit is an outbound Hotline client.

# Logs go to stderr; Docker's default logger picks that up.
CMD ["/usr/local/bin/heidrun-spirit"]
