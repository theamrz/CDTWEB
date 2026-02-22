import Foundation

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    let path: String      // masir nesbi nesbat be root
    let isDirectory: Bool
    let size: Int64?

    var iconSystemName: String {
        isDirectory ? "folder" : "doc.text"
    }
}

enum FileEnumerator {
    static func enumerate(root: URL, showHidden: Bool) -> [FileItem] {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .isHiddenKey]
        var items: [FileItem] = []

        // enumerator recursive; package ha ro skip nemikonim (ghabele taghir)
        guard let e = fm.enumerator(at: root,
                                    includingPropertiesForKeys: keys,
                                    options: [.skipsPackageDescendants],
                                    errorHandler: { url, err in
                                        print("Enum error at \(url): \(err)")
                                        return true
                                    }) else {
            return []
        }

        for case let url as URL in e {
            do {
                let values = try url.resourceValues(forKeys: Set(keys))
                if values.isHidden == true && !showHidden { continue }

                let isDir = values.isDirectory ?? false
                let size = values.fileSize != nil ? Int64(values.fileSize!) : nil
                let relative = url.path
                    .replacingOccurrences(of: root.path, with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if relative.isEmpty { continue }

                items.append(FileItem(url: url, path: relative, isDirectory: isDir, size: size))
            } catch { continue }
        }

        // sort: directory ha aval, ba'd bar asase name
        return items.sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory && !$1.isDirectory }
            return $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending
        }
    }
}
