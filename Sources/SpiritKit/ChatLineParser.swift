import Foundation

/// Parses a Hotline public-chat line. The server formats lines as
/// `"nick:  body"` (two spaces), the same split the 2002 module used.
public enum ChatLineParser {
    public static func parse(_ line: String) -> (nick: String?, body: String) {
        guard let range = line.range(of: ":  ") else {
            return (nil, line)
        }
        let nick = String(line[line.startIndex..<range.lowerBound])
        let body = String(line[range.upperBound...])
        return (nick, body)
    }
}
