import Foundation
import HeidrunCore
import HeidrunNIOClient
import SpiritKit

func log(_ message: String) {
    FileHandle.standardError.write(Data("[heidrun-spirit] \(message)\n".utf8))
}

// Dedicated queue: the Dispatch main queue isn't reliably serviced under
// Swift's async top-level entry, so don't hang the signal source off `.main`.
let signalQueue = DispatchQueue(label: "heidrun-spirit.signals")

func installSignalHandler(_ handler: @escaping @Sendable () -> Void) -> [DispatchSourceSignal] {
    [SIGINT, SIGTERM].map { sig in
        signal(sig, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: sig, queue: signalQueue)
        source.setEventHandler(handler: handler)
        return source
    }
}

// --- Config ---
let config: SpiritConfig
do {
    config = try SpiritConfig()
} catch {
    FileHandle.standardError.write(Data("Configuration error: \(error)\n".utf8))
    exit(2)
}

// --- Engine (one shared instance; MegaHAL is process-global) ---
let brainDirectory = URL(fileURLWithPath: config.brainPath)
do {
    try BrainSeed.ensure(at: brainDirectory)
} catch {
    FileHandle.standardError.write(Data("Brain directory error: \(error)\n".utf8))
    exit(3)
}
let brain = MegaHALBrain()
await brain.start(brainDirectory: brainDirectory)

// --- Save + exit cleanly on SIGINT/SIGTERM ---
let signalSources = installSignalHandler {
    Task {
        await brain.stop()
        exit(0)
    }
}
signalSources.forEach { $0.resume() }

log("heidrun-spirit starting → \(config.settings.address):\(config.settings.port) as \"\(config.nickname)\"")

// --- Reconnect loop with capped backoff ---
var backoff: UInt64 = 2
while true {
    do {
        let client = try await NIOHotlineClient.connect(settings: config.settings)
        try await client.login(
            name: config.settings.login,
            password: config.password,
            nickname: config.nickname,
            icon: config.settings.icon,
            emoji: config.emoji
        )
        log("connected + logged in")
        backoff = 2

        let bot = SpiritBot(
            engine: brain,
            ownNickname: config.nickname,
            autosaveEvery: config.autosaveEvery,
            send: { line in try? await client.sendChat(line, in: nil, isAction: false) }
        )
        await bot.run(events: client.events)   // returns on .disconnected
        await client.disconnect()
        log("disconnected — reconnecting")
    } catch {
        log("connect failed: \(error) — retrying in \(backoff)s")
    }
    try? await Task.sleep(nanoseconds: backoff * 1_000_000_000)
    backoff = min(backoff * 2, 30)
}
