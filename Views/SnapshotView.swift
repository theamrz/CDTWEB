import SwiftUI
import AppKit

struct SnapshotView: View {
    @EnvironmentObject var workspace: WorkspaceStore

    @State private var config: BackupConfiguration = BackupConfiguration.load()
    @State private var isRunning = false
    @State private var lastResult: SnapshotResult? = nil
    @State private var logLines: [String] = []
    @State private var skipDirsText: String = ""
    @State private var skipFilesText: String = ""
    @State private var codeExtText: String = ""
    @State private var allExtText: String = ""

    var body: some View {
        ZStack {
            LiquidGlassBackground()
                .ignoresSafeArea()

            GlassContainer {
                VStack(alignment: .leading, spacing: 18) {
                    logoHeader
                    header
                    presetBar
                    options
                    actions
                    logs
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(32)
        }
        .navigationTitle("Snapshot")
        .onAppear(perform: syncTextsFromConfig)
    }

    private var logoHeader: some View {
        HStack(spacing: 12) {
            if let image = NSImage(contentsOfFile: "/Volumes/Code/TBcms/Project/CDTWEB/CDTWEB/CDTWEB(CodeDevToolsWriteEditeBackup).png") {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(radius: 6)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Code Dev Tools – Snapshot")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Write / Edit / Backup")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workspace")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
            Text(workspace.rootURL?.path ?? "انتخاب نشده")
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var presetBar: some View {
        HStack(spacing: 10) {
            Button("Swift") { config = .swiftDefault; config.save() }
                .buttonStyle(GlassButtonStyle(tint: .cyan))
            Button("TypeScript") { config = .typescriptDefault; config.save() }
                .buttonStyle(GlassButtonStyle(tint: .purple))
            Button("Minimal") { config = .minimal; config.save() }
                .buttonStyle(GlassButtonStyle(tint: .orange))
            Spacer()
        }
        .opacity(isRunning ? 0.5 : 1)
        .disabled(isRunning)
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outputs")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            HStack(spacing: 14) {
                Toggle("Markdown (snapshot.md)", isOn: $config.generateMarkdown)
                Toggle("Text (snapshot.txt)", isOn: $config.generateTxt)
            }
            HStack(spacing: 14) {
                Toggle("Tree (tree.txt)", isOn: $config.generateTree)
                Toggle("Paths (paths.txt)", isOn: $config.generatePaths)
            }
            HStack(spacing: 14) {
                Toggle("Configs", isOn: $config.generateConfigs)
                Toggle("ZIP", isOn: $config.createZip)
            }
            HStack(spacing: 14) {
                Toggle("Include hidden", isOn: $config.includeHidden)
                Toggle("Use Jalali stamp", isOn: $config.useJalaliDate)
            }

            Divider().opacity(0.35)

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Skip directories (comma)") {
                        TextField("node_modules,.git,tmp", text: $skipDirsText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(updateCustomFields)
                    }
                    LabeledContent("Skip files/patterns") {
                        TextField("*.xcuserstate,.DS_Store", text: $skipFilesText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(updateCustomFields)
                    }
                    LabeledContent("Code extensions") {
                        TextField(".swift,.ts,.tsx", text: $codeExtText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(updateCustomFields)
                    }
                    LabeledContent("All extensions") {
                        TextField(".swift,.h,.m,.json,...", text: $allExtText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(updateCustomFields)
                    }
                    LabeledContent("Max file size (KB)") {
                        Stepper(value: $config.maxFileSizeKB, in: 64...8192, step: 64) {
                            Text("\(config.maxFileSizeKB) KB")
                        }
                    }
                }
                .onChange(of: skipDirsText) { _ in updateCustomFields() }
                .onChange(of: skipFilesText) { _ in updateCustomFields() }
                .onChange(of: codeExtText) { _ in updateCustomFields() }
                .onChange(of: allExtText) { _ in updateCustomFields() }
            } label: {
                Text("Advanced filters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .toggleStyle(.switch)
        .onChange(of: config) { _ in config.save() }
        .opacity(isRunning ? 0.6 : 1)
        .disabled(isRunning)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button(action: runSnapshot) {
                Label(isRunning ? "Running..." : "Create Snapshot", systemImage: "camera.on.rectangle")
            }
            .buttonStyle(GlassButtonStyle(tint: .green))
            .disabled(workspace.rootURL == nil || isRunning)
            .opacity(workspace.rootURL == nil || isRunning ? 0.4 : 1)

            if let out = lastResult?.outputDirectory {
                Button("Open Output") {
                    NSWorkspace.shared.open(out)
                }
                .buttonStyle(GlassButtonStyle(tint: .cyan))
            }

            Spacer()
        }
    }

    private var logs: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Logs")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            if logLines.isEmpty {
                Text("هنوز چیزی تولید نشده.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(logLines.indices, id: \.self) { i in
                            Text(logLines[i])
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(minHeight: 140, maxHeight: 240)
            }
        }
    }

    // MARK: - Actions

    private func runSnapshot() {
        guard let root = workspace.rootURL else { return }
        isRunning = true
        logLines.removeAll()
        lastResult = nil

        let configCopy = config
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try SnapshotService.createSnapshot(root: root, configuration: configCopy) { line in
                    DispatchQueue.main.async { self.logLines.append(line) }
                }
                DispatchQueue.main.async {
                    self.lastResult = result
                    self.isRunning = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.logLines.append("ERROR: \(error)")
                    self.isRunning = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func syncTextsFromConfig() {
        skipDirsText = joinSet(config.customSkipDirectories)
        skipFilesText = joinSet(config.customSkipFiles)
        codeExtText = joinSet(config.customCodeExtensions.union(config.codeExtensions))
        allExtText = joinSet(config.customAllExtensions.union(config.allExtensions))
    }

    private func updateCustomFields() {
        config.customSkipDirectories = splitToSet(skipDirsText)
        config.customSkipFiles = splitToSet(skipFilesText)
        let baseCode = splitToSet(codeExtText)
        if !baseCode.isEmpty { config.customCodeExtensions = baseCode }
        let baseAll = splitToSet(allExtText)
        if !baseAll.isEmpty { config.customAllExtensions = baseAll }
        config.save()
    }

    private func splitToSet(_ text: String) -> Set<String> {
        Set(text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty })
    }

    private func joinSet(_ set: Set<String>) -> String {
        set.sorted().joined(separator: ",")
    }
}
