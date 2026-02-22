import SwiftUI

struct FolderPickerButton: View {
    @EnvironmentObject var workspace: WorkspaceStore

    var body: some View {
        Button {
            workspace.pickWorkspace()
        } label: {
            Label("Select Workspace", systemImage: "folder.badge.plus")
        }
    }
}
