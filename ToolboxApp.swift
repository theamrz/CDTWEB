import SwiftUI

@main
struct ToolboxApp: App {
    // state sarsari app: workspace va settings
    @StateObject private var workspaceStore = WorkspaceStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workspaceStore) // inja state ro be hame view ha midim
        }
        .windowStyle(.titleBar)
    }
}
