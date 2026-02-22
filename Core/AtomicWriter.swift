import Foundation

enum AtomicWriter {
    // neveshtan atomik: aval temp, ba'd replace
    static func writeAtomically(to url: URL, content: Data) throws {
        let fm = FileManager.default
        let dir = url.deletingLastPathComponent()
        try fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)

        // If the file doesn't exist, Foundation's `.atomic` write is already safe and simple.
        guard fm.fileExists(atPath: url.path) else {
            try content.write(to: url, options: .atomic)
            return
        }

        let tmpURL = dir.appendingPathComponent(".tmp_" + UUID().uuidString)
        try content.write(to: tmpURL, options: .atomic)

        // Signature changed: replaceItemAt returns the resulting URL (optional) in modern SDKs.
        _ = try fm.replaceItemAt(url, withItemAt: tmpURL, backupItemName: nil, options: [])
    }
}
