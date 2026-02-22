import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workspace: WorkspaceStore
    @State private var searchText: String = ""
    @State private var showHidden: Bool = false

    var body: some View {
        ZStack {
            LiquidGlassBackground()
                .ignoresSafeArea()

            NavigationView {
                GlassContainer { sidebar }
                GlassContainer { main }
            }
            .navigationTitle("Toolbox")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    FolderPickerButton()
                }
                ToolbarItem(placement: .automatic) {
                    Toggle("Hidden", isOn: $showHidden)
                        .onChange(of: showHidden) { _ in
                            workspace.refresh(showHiddenFiles: showHidden)
                        }
                }
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: WriteFromBlocksView()) {
                        Label("Write from Blocks", systemImage: "square.and.pencil")
                    }
                    .disabled(workspace.rootURL == nil)
                }
            }
            .padding(32)
            .background(Color.clear)
        }
        .onAppear {
            workspace.restoreBookmarkIfAvailable()
            workspace.refresh(showHiddenFiles: showHidden)
        }
    }

    private var sidebar: some View {
        List {
            Section("App") {
                NavigationLink(destination: AboutView()) {
                    HStack(spacing: 12) {
                        Image("TayBerryLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(radius: 4)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CDTWEB")
                                .font(.subheadline.weight(.semibold))
                            Text("TayBerry Developers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            Section("Workspace") {
                Text(workspace.rootURL?.path ?? "انتخاب نشده")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if let count = workspace.itemsCount {
                    Text("Files: \(count)")
                }
            }
            Section("Actions") {
                NavigationLink(destination: WriteFromBlocksView()) {
                    Label("Write from Blocks", systemImage: "square.and.pencil")
                }
                .disabled(workspace.rootURL == nil)

                NavigationLink(destination: SnapshotView()) {
                    Label("Snapshot (Tree/Paths/Code)", systemImage: "camera.on.rectangle")
                }
                .disabled(workspace.rootURL == nil)

                Label("Batch Replace (بعدی)", systemImage: "rectangle.3.group")
                Label("Split File (بعدی)", systemImage: "scissors")
                Label("Backup/Restore (بعدی)", systemImage: "clock.arrow.circlepath")
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.sidebar)
        .frame(minWidth: 260)
        .frame(maxHeight: .infinity)
    }

    private var main: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                TextField("جستجو در نام فایل…", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                    .onChange(of: searchText) { _ in
                        workspace.filter(query: searchText)
                    }

                Spacer()

                if let root = workspace.rootURL {
                    Text("In · \(root.lastPathComponent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule(style: .continuous))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 4)

            FileListView(items: workspace.filteredItems)
                .overlay {
                    if workspace.rootURL == nil {
                        ContentPlaceholder(title: "Workspace را انتخاب کن",
                                           subtitle: "از نوار ابزار روی پوشه کلیک کن")
                    } else if workspace.filteredItems.isEmpty {
                        ContentPlaceholder(title: "فایلی یافت نشد",
                                           subtitle: "فیلتر جستجو را پاک کن یا Hidden را فعال کن")
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentPlaceholder: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title3)
                .bold()
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("TayBerryLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(radius: 10)
            
            VStack(spacing: 8) {
                Text("CDTWEB")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("CodeDevTools Write • Edit • Backup")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                Text("Developed by TayBerry Developers")
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 16) {
                    Link("tayberry.ir", destination: URL(string: "https://tayberry.ir")!)
                    Link("tayberry.dev", destination: URL(string: "https://tayberry.dev")!)
                }
                .font(.callout)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding(40)
        .frame(width: 400, height: 400)
    }
}
