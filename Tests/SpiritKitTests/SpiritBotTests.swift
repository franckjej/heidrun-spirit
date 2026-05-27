import Testing
@testable import SpiritKit

/// Fake engine: echoes a fixed reply and counts saves — no real MegaHAL.
private actor FakeEngine: ChatEngine {
    let canned: String
    private(set) var saveCount = 0
    init(canned: String) { self.canned = canned }
    func reply(to input: String) async -> String { canned }
    func save() async { saveCount += 1 }
    func saves() -> Int { saveCount }
}

/// Captures what the bot would send.
private actor Sent {
    private(set) var lines: [String] = []
    func add(_ line: String) { lines.append(line) }
    func all() -> [String] { lines }
}

@Suite("SpiritBot")
struct SpiritBotTests {
    private func makeBot(engine: FakeEngine, sent: Sent, ownNick: String = "Spirit", autosave: Int = 25) -> SpiritBot {
        SpiritBot(
            engine: engine,
            ownNickname: ownNick,
            autosaveEvery: autosave,
            send: { line in await sent.add(line) }
        )
    }

    @Test("replies to a peer's line")
    func repliesToPeer() async {
        let engine = FakeEngine(canned: "BANANA")
        let sent = Sent()
        let bot = makeBot(engine: engine, sent: sent)
        await bot.handleChatLine("Bob:  hello?")
        #expect(await sent.all() == ["BANANA"])
    }

    @Test("ignores its own echoed line")
    func ignoresSelf() async {
        let engine = FakeEngine(canned: "BANANA")
        let sent = Sent()
        let bot = makeBot(engine: engine, sent: sent)
        await bot.handleChatLine("Spirit:  BANANA")
        #expect(await sent.all().isEmpty)
    }

    @Test("autosaves every N replies")
    func autosaves() async {
        let engine = FakeEngine(canned: "x")
        let sent = Sent()
        let bot = makeBot(engine: engine, sent: sent, autosave: 2)
        await bot.handleChatLine("Bob:  one")
        await bot.handleChatLine("Bob:  two")   // 2nd reply -> save
        #expect(await engine.saves() == 1)
    }
}
