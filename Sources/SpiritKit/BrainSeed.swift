import Foundation

/// Seeds a writable brain directory from the bundled MegaHAL training data.
/// MegaHAL writes its brain back as it learns, so it can't run from the
/// read-only resource bundle — copy the seed files that are missing.
public enum BrainSeed {
    private static let files = [
        "megahal.dic", "megahal.trn", "megahal.ban",
        "megahal.aux", "megahal.swp", "megahal.grt"
    ]

    public static func ensure(at directory: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let seedDirectory = Bundle.module.resourceURL?.appendingPathComponent("brain") else {
            return
        }
        for name in files {
            let destination = directory.appendingPathComponent(name)
            guard !fileManager.fileExists(atPath: destination.path) else { continue }
            let source = seedDirectory.appendingPathComponent(name)
            if fileManager.fileExists(atPath: source.path) {
                try fileManager.copyItem(at: source, to: destination)
            }
        }
    }
}
