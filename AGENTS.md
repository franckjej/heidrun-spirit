# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Cursor, Aider, …) working in this repo.

For project-facing detail see [`README.md`](README.md). Deploy specifics live in [`deploy/README.md`](deploy/README.md). This file is what an agent needs *additionally* to do useful work.

## What this is

**heidrun-spirit** — a Swift 6 Hotline chatterbot wrapping the 1998 [MegaHAL](https://megahal.alioth.debian.org/) Markov engine. Outbound-only client; connects to a Hotline server and replies to chat. Repo: `franckjej/heidrun-spirit`, work branch `main`.

Hotline wire types and the cross-platform transport (`HeidrunNIOClient`) live in [`franckjej/heidrun-protocol`](https://github.com/franckjej/heidrun-protocol). **Wire-format edits happen there, not here.**

**Do not push to `origin/main` without explicit user confirmation.** Local commits are typically ahead of the remote until the user pushes themselves.

## Repo layout

```
Package.swift                       3 targets: CMegaHAL, SpiritKit, heidrun-spirit
Sources/
  CMegaHAL/                         1998 C engine, unmodified, with include/
  SpiritKit/                        Swift wrapper: ChatEngine, MegaHALBrain, BrainSeed,
                                                  ChatLineParser, SpiritConfig, SpiritBot
    Resources/brain/                bundled training data (megahal.{dic,trn})
  heidrun-spirit/                   @main executable; connect/reconnect loop + signals
Tests/SpiritKitTests/               .serialized — see "Gotchas" below
Dockerfile  docker-compose.yml      Linux deploy
deploy/
  launchd/org.tastybytes.heidrun-spirit.plist   macOS LaunchDaemon
  README.md
```

## Commands

Pure SwiftPM — no Xcode project. Use `swift` directly.

```bash
swift run heidrun-spirit                                      # local run
swift build                                                   # build only
swift test                                                    # Swift Testing — not XCTest
swift package resolve                                         # refresh heidrun-protocol pin

docker build -t heidrun-spirit .
docker compose up -d --build
```

## Gotchas

### MegaHAL is process-global C state

`megahal_initial_greeting`, `megahal_do_reply`, etc. mutate static C globals. There can be exactly **one** `MegaHALBrain` actor per process. Tests that exercise the engine must be `.serialized`; concurrent calls **will** corrupt state.

### `-UDEBUG` on the C target

SwiftPM defines `DEBUG=1` in debug builds, which would pull MegaHAL's dropped `debug.h`. Package.swift's `CMegaHAL` target sets `-std=gnu89 -w -UDEBUG` to compile the 1998 source untouched. Don't touch these flags.

### Resource-bundle location varies by platform

The bundled brain (`megahal.dic`, `megahal.trn`) ships in SpiritKit's resource bundle. SwiftPM names it differently per OS:

- **macOS**: `heidrun-spirit_SpiritKit.bundle`
- **Linux**: `heidrun-spirit_SpiritKit.resources`

The Dockerfile uses `find .build/release/ -maxdepth 1 \( -name '*.bundle' -o -name '*.resources' \)` to stage whichever form exists. `Bundle.module` on non-Darwin reads from `.resources/` next to the executable; on Darwin from `.bundle/`.

### Self-filter by nickname

The bot's chat-line parser splits heidrun-server's `" <nick>: <body>\r"` format (leading space + ONE space after the colon, trailing CR) on the **first `": "`** — not on `":  "`. Misparsing causes an infinite self-reply loop that also pollutes the brain. Don't change the split delimiter without testing against a real server.

## Code style

<important>
**Identifiers must be descriptive and at least 3 characters long.** Local variables, properties, function parameters, closure parameters, case-binding names, tuple element labels.

- ❌ `let fm = FileManager.default` / `case .failure(let e):` / `{ s in ... }`
- ✅ `let fileManager = FileManager.default` / `case .failure(let error):` / `{ socket in ... }`

Narrow exemptions: generic type parameters (`T`, `U`, `V`); anonymous closure shorthand (`$0`); the Swift argument *label* `id:`; math/coordinate variables in tight scopes (`x`, `y`, `z`, `i`, `j`).
</important>

## Tag / version convention

Bare semver (no `v` prefix). Pin pre-release tags with `exact:`, never `from:` — SemVer pre-release identifiers compare lexically, so `from: "1.0.0-rc10"` quietly resolves back to `rc9`.
