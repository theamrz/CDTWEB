import SwiftUI
import AppKit

// key baraye zakhire-ye bookmark dar UserDefaults
private let kWorkspaceBookmarkKey = "workspace.bookmark"

final class WorkspaceStore: ObservableObject {
    @Published var rootURL: URL? = nil
    @Published var allItems: [FileItem] = []
    @Published var filteredItems: [FileItem] = []
    @Published var itemsCount: Int? = nil

    private var isAccessingBookmark = false

    // restore bookmark (agar ghablan sabt shode)
    func restoreBookmarkIfAvailable() {
        guard rootURL == nil else { return }
        guard let data = UserDefaults.standard.data(forKey: kWorkspaceBookmarkKey) else { return }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data,
                              options: [.withSecurityScope],
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            if isStale {
                try saveBookmark(for: url) // update bookmark age ghadimi shode
            }
            startAccess(url)
            rootURL = url
        } catch {
            print("Bookmark restore failed: \(error)")
        }
    }

    // sabt bookmark jadid
    private func saveBookmark(for url: URL) throws {
        let data = try url.bookmarkData(options: [.withSecurityScope],
                                        includingResourceValuesForKeys: nil,
                                        relativeTo: nil)
        UserDefaults.standard.set(data, forKey: kWorkspaceBookmarkKey)
    }

    // shoroo dastresi be bookmark
    private func startAccess(_ url: URL) {
        if url.startAccessingSecurityScopedResource() {
            isAccessingBookmark = true
        }
    }

    // payan dastresi (mesalan dar app termination seda bezan)
    func stopAccessIfNeeded() {
        if isAccessingBookmark {
            rootURL?.stopAccessingSecurityScopedResource()
            isAccessingBookmark = false
        }
    }

    // entekhab workspace ba NSOpenPanel
    func pickWorkspace() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Workspace"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try saveBookmark(for: url)
                startAccess(url)
                rootURL = url
                refresh(showHiddenFiles: false)
            } catch {
                print("Failed to set workspace: \(error)")
            }
        }
    }

    // load list-e file ha
    func refresh(showHiddenFiles: Bool) {
        guard let root = rootURL else {
            allItems = []; filteredItems = []; itemsCount = 0; return
        }
        allItems = FileEnumerator.enumerate(root: root, showHidden: showHiddenFiles)
        itemsCount = allItems.count
        filteredItems = allItems
    }

    // filter bar asase query
    func filter(query: String) {
        guard !query.isEmpty else {
            filteredItems = allItems; return
        }
        let q = query.lowercased()
        filteredItems = allItems.filter { $0.path.lowercased().contains(q) }
    }
}
