import Testing
import HeidrunCore
@testable import SpiritKit

@Suite("SpiritConfig")
struct SpiritConfigTests {
    @Test("parses a full environment")
    func parsesFull() throws {
        let env = [
            "HEIDRUN_SPIRIT_HOST": "h.example.com",
            "HEIDRUN_SPIRIT_PORT": "5500",
            "HEIDRUN_SPIRIT_NICK": "Spirit",
            "HEIDRUN_SPIRIT_EMOJI": "🤖",
            "HEIDRUN_SPIRIT_AUTOSAVE": "10"
        ]
        let config = try SpiritConfig(environment: env)
        #expect(config.nickname == "Spirit")
        #expect(config.emoji == "🤖")
        #expect(config.autosaveEvery == 10)
        #expect(config.settings.address == "h.example.com")
        #expect(config.settings.port == 5500)
        #expect(config.settings.emoji == "🤖")
    }

    @Test("missing HOST throws a configuration error")
    func missingHostThrows() {
        #expect(throws: SpiritConfig.ConfigError.self) {
            _ = try SpiritConfig(environment: [:])
        }
    }

    @Test("applies sensible defaults")
    func defaults() throws {
        let config = try SpiritConfig(environment: ["HEIDRUN_SPIRIT_HOST": "h"])
        #expect(config.nickname == "Heidrun's Spirit")
        #expect(config.settings.port == 5500)
        #expect(config.autosaveEvery == 25)
        #expect(config.emoji == nil)
        #expect(config.brainPath == "./brain")
    }
}
