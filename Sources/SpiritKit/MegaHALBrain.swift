import Foundation
import CMegaHAL

/// Swift actor around the reused MegaHAL C engine. MegaHAL is global,
/// single-threaded C state (not reentrant), so this actor serializes every
/// call into it and there must be exactly one instance per process.
public actor MegaHALBrain: ChatEngine {
    private var started = false

    public init() {}

    /// Point MegaHAL at a writable brain directory and train/load the model.
    public func start(brainDirectory: URL) {
        guard !started else { return }
        // `set_default_directory` strcpy's into its own buffer, so freeing
        // our copy afterwards is safe.
        let dir = strdup(brainDirectory.path)
        defer { free(dir) }
        set_default_directory(dir)
        megahal_setnobanner()
        megahal_setnoprompt()
        megahal_setnowrap()
        megahal_initialize()
        started = true
    }

    public func reply(to input: String) async -> String {
        guard started else { return "" }
        // `megahal_do_reply` uppercases the input buffer in place, so pass a
        // mutable copy. The returned pointer is MegaHAL-internal — copy it out.
        let mutableInput = strdup(input)
        defer { free(mutableInput) }
        guard let output = megahal_do_reply(mutableInput, 0) else { return "" }
        return String(cString: output)
    }

    public func save() async {
        guard started else { return }
        let command = strdup("#SAVE")
        defer { free(command) }
        _ = megahal_command(command)
    }

    public func stop() {
        guard started else { return }
        let command = strdup("#SAVE")
        defer { free(command) }
        _ = megahal_command(command)
        megahal_cleanup()
        started = false
    }
}
