import Testing
import Foundation
@testable import SpiritKit

// `.serialized` is mandatory: MegaHAL holds its model in process-global C
// state, so it's a process-wide singleton. Parallel tests would init it
// twice over the same globals and abort.
@Suite("MegaHALBrain", .serialized)
struct MegaHALBrainTests {
    @Test("start then reply returns non-empty text")
    func replies() async throws {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spirit-brain-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        try BrainSeed.ensure(at: temp)

        let brain = MegaHALBrain()
        await brain.start(brainDirectory: temp)
        let reply = await brain.reply(to: "Hello there, tell me about Hotline!")
        await brain.save()
        await brain.stop()

        #expect(!reply.isEmpty)
    }
}
