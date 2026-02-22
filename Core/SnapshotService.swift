import Foundation
import Darwin

struct SnapshotResult {
    let outputDirectory: URL
    let includedFileCount: Int
    let includedTotalBytes: Int64
    let skippedFileCount: Int
}

enum SnapshotService {
    private struct SnapshotFile {
        enum Kind: String, Codable { case code, config }

        let url: URL
        let relativePath: String
        let kind: Kind
        let size: Int64
    }

    private struct Manifest: Codable {
        let createdAtISO: String
        let createdAtJalali: String?
        let rootPath: String
        let outputPath: String
        let includedFileCount: Int
        let includedTotalBytes: Int64
        let skippedFileCount: Int
        let configuration: BackupConfiguration
        let outputs: [String]
    }

    static func createSnapshot(root: URL, configuration: BackupConfiguration, log: (String) -> Void) throws -> SnapshotResult {
        let fm = FileManager.default
        let now = Date()

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let stampISO = iso.string(from: now)

        let stampFolder: String
        let stampJalali: String?
        if configuration.useJalaliDate {
            let s = JalaliDateConverter.formatStamp(now)
            stampFolder = s
            stampJalali = JalaliDateConverter.formatReadable(now)
        } else {
            stampFolder = stampISO
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: ".", with: "-")
            stampJalali = nil
        }

        let outDir = root
            .appendingPathComponent(".toolbox/Snapshots", isDirectory: true)
            .appendingPathComponent("Snapshot_" + stampFolder, isDirectory: true)
        try fm.createDirectory(at: outDir, withIntermediateDirectories: true, attributes: nil)
        log("Output: \(outDir.path)")

        let collected = collectFiles(root: root, configuration: configuration, log: log)
        let included = collected.included
        let skippedCount = collected.skippedCount

        var outputs: [String] = []

        if configuration.generatePaths {
            let content = included.map(\.relativePath).joined(separator: "\n") + "\n"
            try AtomicWriter.writeAtomically(to: outDir.appendingPathComponent("paths.txt"), content: Data(content.utf8))
            outputs.append("paths.txt")
        }

        if configuration.generateTree {
            let content = renderTree(paths: included.map(\.relativePath))
            try AtomicWriter.writeAtomically(to: outDir.appendingPathComponent("tree.txt"), content: Data(content.utf8))
            outputs.append("tree.txt")
        }

        if configuration.generateMarkdown {
            let content = try renderBundle(files: included, root: root, configuration: configuration, format: .markdown, log: log)
            try AtomicWriter.writeAtomically(to: outDir.appendingPathComponent("snapshot.md"), content: Data(content.utf8))
            outputs.append("snapshot.md")
        }

        if configuration.generateTxt {
            let content = try renderBundle(files: included, root: root, configuration: configuration, format: .plainText, log: log)
            try AtomicWriter.writeAtomically(to: outDir.appendingPathComponent("snapshot.txt"), content: Data(content.utf8))
            outputs.append("snapshot.txt")
        }

        let totalBytes = included.reduce(Int64(0)) { $0 + $1.size }
        let manifest = Manifest(
            createdAtISO: stampISO,
            createdAtJalali: stampJalali,
            rootPath: root.path,
            outputPath: outDir.path,
            includedFileCount: included.count,
            includedTotalBytes: totalBytes,
            skippedFileCount: skippedCount,
            configuration: configuration,
            outputs: outputs
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let manifestData = try encoder.encode(manifest)
        try AtomicWriter.writeAtomically(to: outDir.appendingPathComponent("manifest.json"), content: manifestData)
        outputs.append("manifest.json")

        if configuration.createZip {
            do {
                // Put the zip next to the snapshot folder to avoid zipping "into itself".
                let zipURL = outDir.deletingLastPathComponent().appendingPathComponent(outDir.lastPathComponent + ".zip")
                try createZip(of: outDir, to: zipURL)
                outputs.append(zipURL.path)
            } catch {
                log("ZIP failed: \(error)")
            }
        }

        log("Done. Included \(included.count) file(s). Skipped \(skippedCount) file(s).")
        return SnapshotResult(outputDirectory: outDir, includedFileCount: included.count, includedTotalBytes: totalBytes, skippedFileCount: skippedCount)
    }

    // MARK: - Collect

    private static func collectFiles(root: URL, configuration: BackupConfiguration, log: (String) -> Void) -> (included: [SnapshotFile], skippedCount: Int) {
        let fm = FileManager.default
        var included: [SnapshotFile] = []
        var skipped = 0

        let rootPath = root.standardizedFileURL.path
        let maxBytes = Int64(configuration.maxFileSizeKB) * 1024

        // Pre-calc to avoid repeated bridging.
        let allExt = configuration.allExtensions
            .union(configuration.customAllExtensions)
        let codeExt = configuration.codeExtensions
            .union(configuration.customCodeExtensions)
        let skipDirs = configuration.skipDirectories
            .union(configuration.customSkipDirectories)
        let skipFiles = Array(configuration.skipFiles.union(configuration.customSkipFiles))
        let skipTests = configuration.skipTestPatterns
        let configPatterns = configuration.configPatterns

        var queue: [URL] = [root]
        while let current = queue.popLast() {
            guard let children = try? fm.contentsOfDirectory(at: current, includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey, .fileSizeKey], options: []) else {
                skipped += 1
                continue
            }

            for child in children {
                let name = child.lastPathComponent

                let values = (try? child.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey, .fileSizeKey])) ?? URLResourceValues()
                if values.isHidden == true && !configuration.includeHidden {
                    skipped += 1
                    continue
                }

                let isDir = values.isDirectory == true
                if isDir {
                    if skipDirs.contains(name) {
                        skipped += 1
                        continue
                    }
                    queue.append(child)
                    continue
                }

                // Compute relative path.
                let childPath = child.standardizedFileURL.path
                guard childPath == rootPath || childPath.hasPrefix(rootPath + "/") else {
                    skipped += 1
                    continue
                }
                let relative = String(childPath.dropFirst(rootPath.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if relative.isEmpty {
                    continue
                }

                // Skip patterns.
                if matchesAny(patterns: skipFiles, relativePath: relative) || matchesAny(patterns: skipTests, relativePath: relative) {
                    skipped += 1
                    continue
                }

                let size = Int64(values.fileSize ?? 0)
                if size > maxBytes {
                    skipped += 1
                    continue
                }

                let kind: SnapshotFile.Kind?
                if matchesAny(patterns: configPatterns, relativePath: relative) {
                    kind = .config
                } else {
                    let ext = "." + child.pathExtension.lowercased()
                    if allExt.contains(ext) || codeExt.contains(ext) {
                        kind = .code
                    } else {
                        kind = nil
                    }
                }

                guard let kind else {
                    skipped += 1
                    continue
                }

                included.append(SnapshotFile(url: child, relativePath: relative, kind: kind, size: size))
            }
        }

        included.sort { $0.relativePath.localizedCaseInsensitiveCompare($1.relativePath) == .orderedAscending }
        log("Collected \(included.count) include file(s).")
        return (included, skipped)
    }

    // MARK: - Render

    private enum BundleFormat { case markdown, plainText }

    private static func renderBundle(
        files: [SnapshotFile],
        root: URL,
        configuration: BackupConfiguration,
        format: BundleFormat,
        log: (String) -> Void
    ) throws -> String {
        var out: [String] = []
        out.append("Root: \(root.path)")
        out.append("Created: \(ISO8601DateFormatter().string(from: Date()))")
        out.append("Files: \(files.count)")
        out.append("")

        let includeConfigs = configuration.generateConfigs
        for file in files {
            if file.kind == .config && !includeConfigs {
                continue
            }

            guard FileGuard.isInsideRoot(target: file.url, root: root) else {
                log("SKIP (outside root): \(file.relativePath)")
                continue
            }

            let text: String
            do {
                text = try String(contentsOf: file.url, encoding: .utf8)
            } catch {
                log("SKIP (non-utf8): \(file.relativePath)")
                continue
            }

            switch format {
            case .plainText:
                out.append("----- \(file.relativePath) -----")
                out.append(text)
                if !text.hasSuffix("\n") { out.append("") }
                out.append("")
            case .markdown:
                out.append("## \(file.relativePath)")
                let lang = languageHint(for: file.url.pathExtension)
                let fence = codeFence(for: text)
                out.append("\(fence)\(lang)")
                out.append(text)
                if !text.hasSuffix("\n") { out.append("") }
                out.append(fence)
                out.append("")
            }
        }

        return out.joined(separator: "\n")
    }

    private static func languageHint(for ext: String) -> String {
        switch ext.lowercased() {
        case "swift": return "swift"
        case "m", "mm": return "objectivec"
        case "h": return "c"
        case "js": return "javascript"
        case "ts": return "typescript"
        case "tsx": return "tsx"
        case "json": return "json"
        case "yml", "yaml": return "yaml"
        case "md": return "markdown"
        case "sh": return "bash"
        case "html": return "html"
        case "css": return "css"
        case "plist": return "xml"
        default: return ""
        }
    }

    private static func codeFence(for content: String) -> String {
        // Pick a fence length that's longer than any run of backticks in the file.
        var maxRun = 0
        var run = 0
        for ch in content {
            if ch == "`" {
                run += 1
                maxRun = max(maxRun, run)
            } else {
                run = 0
            }
        }
        return String(repeating: "`", count: max(3, maxRun + 1))
    }

    private static func renderTree(paths: [String]) -> String {
        final class Node {
            var children: [String: Node] = [:]
            var isFile = false
        }

        let root = Node()
        for path in paths {
            let parts = path.split(separator: "/").map(String.init)
            var n = root
            for (i, part) in parts.enumerated() {
                let child = n.children[part] ?? Node()
                n.children[part] = child
                n = child
                if i == parts.count - 1 { n.isFile = true }
            }
        }

        func render(node: Node, prefix: String) -> [String] {
            let keys = node.children.keys.sorted { a, b in
                let ad = node.children[a]?.isFile == false
                let bd = node.children[b]?.isFile == false
                if ad != bd { return ad && !bd }
                return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
            }

            var lines: [String] = []
            for (idx, key) in keys.enumerated() {
                let child = node.children[key]!
                let isLast = idx == keys.count - 1
                lines.append(prefix + (isLast ? "`-- " : "|-- ") + key)
                if !child.isFile {
                    let nextPrefix = prefix + (isLast ? "    " : "|   ")
                    lines.append(contentsOf: render(node: child, prefix: nextPrefix))
                }
            }
            return lines
        }

        return (["."] + render(node: root, prefix: "")).joined(separator: "\n") + "\n"
    }

    // MARK: - Glob/pattern helpers

    private static func matchesAny(patterns: [String], relativePath: String) -> Bool {
        let name = (relativePath as NSString).lastPathComponent
        for pattern in patterns {
            let candidate = pattern.contains("/") ? relativePath : name
            if fnmatch(pattern, candidate, FNM_CASEFOLD) == 0 {
                return true
            }
        }
        return false
    }

    // MARK: - Zip

    private static func createZip(of directory: URL, to zipURL: URL) throws {
        // Uses Apple's recommended tool for zipping bundles/folders.
        // Note: in App Sandbox this may fail; caller already logs and continues.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", directory.path, zipURL.path]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw NSError(domain: "SnapshotService.Zip", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "ditto failed with status \(process.terminationStatus)"])
        }
    }
}
