import Foundation
import HeidrunCore

/// Bot configuration sourced from environment variables.
public struct SpiritConfig: Sendable {
    public enum ConfigError: Error, CustomStringConvertible {
        case missingHost
        public var description: String {
            switch self {
            case .missingHost: return "HEIDRUN_SPIRIT_HOST is required"
            }
        }
    }

    public let settings: ConnectionSettings
    public let password: String
    public let nickname: String
    public let emoji: String?
    public let brainPath: String
    public let autosaveEvery: Int

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        func value(_ key: String) -> String? {
            let raw = environment["HEIDRUN_SPIRIT_\(key)"]?.trimmingCharacters(in: .whitespaces)
            return (raw?.isEmpty ?? true) ? nil : raw
        }

        guard let host = value("HOST") else { throw ConfigError.missingHost }

        let useTLS = ["1", "true", "yes"].contains((value("TLS") ?? "").lowercased())
        let port = UInt16(value("PORT") ?? "") ?? (useTLS ? 5503 : 5500)
        let nickname = value("NICK") ?? "Heidrun's Spirit"
        let icon = UInt16(value("ICON") ?? "") ?? 0
        let emoji = value("EMOJI")

        self.nickname = nickname
        self.emoji = emoji
        self.password = value("PASSWORD") ?? ""
        self.brainPath = value("BRAIN_PATH") ?? "./brain"
        self.autosaveEvery = max(1, Int(value("AUTOSAVE") ?? "") ?? 25)
        self.settings = ConnectionSettings(
            name: "Heidrun Spirit",
            address: host,
            port: port,
            nickname: nickname,
            login: value("LOGIN") ?? "",
            icon: icon,
            useTLS: useTLS,
            emoji: emoji
        )
    }
}
