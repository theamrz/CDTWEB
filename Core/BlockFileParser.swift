import Foundation

struct WriteBlock: Identifiable {
    let id = UUID()
    let relativePath: String  // masir nesbi ke to header miad
    let content: String       // matn jadid baraye neveshtan
}

enum BlockFileParser {
    // parser baraye format:  --- path/to/file.ext ---
    static func parse(_ text: String) -> [WriteBlock] {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        var blocks: [WriteBlock] = []
        var currentPath: String? = nil
        var buffer: [String] = []

        func flush() {
            guard let p = currentPath else { return }
            blocks.append(WriteBlock(relativePath: p, content: buffer.joined(separator: "\n")))
            buffer.removeAll(keepingCapacity: true)
        }

        let headerPrefix = "--- "
        let headerSuffix = " ---"

        for line in lines {
            if line.hasPrefix(headerPrefix) && line.hasSuffix(headerSuffix) {
                flush()
                let start = line.index(line.startIndex, offsetBy: headerPrefix.count)
                let end = line.index(line.endIndex, offsetBy: -headerSuffix.count)
                currentPath = String(line[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                buffer.append(line)
            }
        }
        flush()
        return blocks
    }
}
