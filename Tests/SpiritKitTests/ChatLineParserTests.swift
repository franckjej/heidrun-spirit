import Testing
@testable import SpiritKit

@Suite("ChatLineParser")
struct ChatLineParserTests {
    @Test("splits a 'nick: body' line")
    func splitsNickAndBody() {
        let result = ChatLineParser.parse("Bob: hi there, friend")
        #expect(result.nick == "Bob")
        #expect(result.body == "hi there, friend")
    }

    @Test("parses heidrun-server's ' nick: body\\r' wire format (leading space, trailing CR)")
    func heidrunServerFormat() {
        let result = ChatLineParser.parse(" Heidrun's Spirit: Beef is the study of the foot.\r")
        #expect(result.nick == "Heidrun's Spirit")
        #expect(result.body == "Beef is the study of the foot.")
    }

    @Test("a nick containing a colon still parses (split on colon-space)")
    func colonInNick() {
        let result = ChatLineParser.parse(" silver:box: hi\r")
        #expect(result.nick == "silver:box")
        #expect(result.body == "hi")
    }

    @Test("a line without ': ' has no nick")
    func noDelimiter() {
        let result = ChatLineParser.parse(" *** Bob has joined")
        #expect(result.nick == nil)
        #expect(result.body == "*** Bob has joined")
    }

    @Test("only the first ': ' splits; later ones stay in the body")
    func firstDelimiterOnly() {
        let result = ChatLineParser.parse("Bob: see this: cool")
        #expect(result.nick == "Bob")
        #expect(result.body == "see this: cool")
    }
}
