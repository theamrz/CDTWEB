import Foundation

enum FileGuard {
    // jologiri az path traversal: target bayad zir-e root bashad
    static func isInsideRoot(target: URL, root: URL) -> Bool {
        let resolvedRoot = root.resolvingSymlinksInPath().standardizedFileURL
        let resolvedTarget = target.resolvingSymlinksInPath().standardizedFileURL
        return resolvedTarget.path == resolvedRoot.path
            || resolvedTarget.path.hasPrefix(resolvedRoot.path + "/")
    }
}
