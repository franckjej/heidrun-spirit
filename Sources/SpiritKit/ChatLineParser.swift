import Foundation

/// Parses a Hotline public-chat line into `(nick, body)`.
///
/// heidrun-server formats public chat as `" <nick>: <body>\r"` — a leading
/// space, a single space after the colon, and a trailing carriage return.
/// (Classic servers used two spaces.) We split on the first `": "` and trim
/// both sides, so the leading space / extra space / `\r` never break the
/// nickname match that the bot's self-filter depends on. A nick containing a
/// colon (e.g. `silver:box`) is fine: we split on colon-**space**, and the
/// server's separator is the first such after the whole nick.
public enum ChatLineParser {
    public static func parse(_ line: String) -> (nick: String?, body: String) {
        guard let range = line.range(of: ": ") else {
            return (nil, line.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let nick = String(line[line.startIndex..<range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let body = String(line[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (nick.isEmpty ? nil : nick, body)
    }
}
