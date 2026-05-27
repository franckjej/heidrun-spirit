/// The bot's pluggable chat engine. MegaHAL (C) is today's implementation;
/// a future pure-Swift, public-domain engine can conform here without
/// touching `SpiritBot`.
public protocol ChatEngine: Sendable {
    /// Reply to a line (the engine also learns from it).
    func reply(to input: String) async -> String
    /// Persist whatever the engine has learned.
    func save() async
}
