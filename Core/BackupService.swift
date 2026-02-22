import Foundation

enum BackupService {
    // agar file mojood bood, ghabl az overwrite yek copy dar .toolbox/Backups/<timestamp>/... migirim
    static func backupIfExists(root: URL, relativePath: String) throws {
        let target = root.appendingPathComponent(relativePath)
        let fm = FileManager.default
        guard fm.fileExists(atPath: target.path) else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let stamp = formatter.string(from: Date())

        let backupRoot = root.appendingPathComponent(".toolbox/Backups/")
        let backupDir = backupRoot.appendingPathComponent(stamp)
        let backupFile = backupDir.appendingPathComponent(relativePath)

        try fm.createDirectory(at: backupFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.copyItem(at: target, to: backupFile)
    }
}
