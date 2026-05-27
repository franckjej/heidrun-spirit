# heidrun-spirit

A standalone Hotline chat bot powered by the classic **MegaHAL** Markov engine
(© 1998 Jason Hutchens, GPLv2) — a Swift revival of the 2002 "Heidrun's Spirit"
module. Logs into a Hotline server and chats.

Licensed **GPLv2** (the bundled MegaHAL C is GPLv2). See `LICENSE`.

## Run

```
swift build -c release
HEIDRUN_SPIRIT_HOST=hotline.example.com .build/release/heidrun-spirit
```

## Deploy

Runs as a macOS `launchd` daemon — see [`deploy/`](deploy/README.md).

**No Docker:** the bot's Hotline client (`HeidrunCore.HotlineNetworkClient`) is
built on Apple's Network framework and is Darwin-only, so it can't run in a
Linux container. A Linux host would need the client ported to SwiftNIO first.
