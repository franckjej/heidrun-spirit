import Testing
@testable import SpiritKit

@Suite("ChatLineParser")
struct ChatLineParserTests {
    @Test("splits a 'nick:  body' line")
    func splitsNickAndBody() {
        let result = ChatLineParser.parse("Bob:  hi there, friend")
        #expect(result.nick == "Bob")
        #expect(result.body == "hi there, friend")
    }

    @Test("a line without the ':  ' delimiter has no nick")
    func noDelimiter() {
        let result = ChatLineParser.parse("*** Bob has joined")
        #expect(result.nick == nil)
        #expect(result.body == "*** Bob has joined")
    }

    @Test("only the first ':  ' splits; later ones stay in the body")
    func firstDelimiterOnly() {
        let result = ChatLineParser.parse("Bob:  see this:  cool")
        #expect(result.nick == "Bob")
        #expect(result.body == "see this:  cool")
    }
}
