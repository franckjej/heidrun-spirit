import Foundation
import HeidrunCore

/// The chatterbox. `handleChatLine` is the pure, testable core; `run`
/// drives it from a live client's event stream.
public actor SpiritBot {
    private let engine: any ChatEngine
    private let ownNickname: String
    private let autosaveEvery: Int
    private let send: @Sendable (String) async -> Void
    private var replyCount = 0

    public init(
        engine: any ChatEngine,
        ownNickname: String,
        autosaveEvery: Int,
        send: @escaping @Sendable (String) async -> Void
    ) {
        self.engine = engine
        self.ownNickname = ownNickname
        self.autosaveEvery = autosaveEvery
        self.send = send
    }

    /// Handle one received public-chat line: skip our own echo, reply, autosave.
    public func handleChatLine(_ rawLine: String) async {
        let parsed = ChatLineParser.parse(rawLine)
        if let nick = parsed.nick, nick == ownNickname { return }

        let reply = await engine.reply(to: parsed.body)
        guard !reply.isEmpty else { return }
        await send(reply)

        replyCount += 1
        if replyCount % autosaveEvery == 0 { await engine.save() }
    }

    /// Consume a client's event stream, replying to public chat. Returns on
    /// `.disconnected` (so the caller can reconnect) or when the stream ends.
    public func run(events: AsyncStream<HotlineEvent>) async {
        for await event in events {
            switch event {
            case let .chatReceived(chat, message, _) where chat == nil:
                await handleChatLine(message)
            case .disconnected:
                return
            default:
                break
            }
        }
    }
}
