import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct WriteFromBlocksView: View {
    @EnvironmentObject var workspace: WorkspaceStore

    @State private var blocks: [WriteBlock] = []
    @State private var selected: Set<UUID> = []
    @State private var diffs: [UUID: (added: Int, removed: Int, unchanged: Int)] = [:]
    @State private var logLines: [String] = []

    var body: some View {
        ZStack {
            LiquidGlassBackground()
                .ignoresSafeArea()

            GlassContainer {
                VStack(alignment: .leading, spacing: 24) {
                    controlBar
                    blocksSection
                    logsSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(32)
        }
        .navigationTitle("Write from Blocks")
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            Button(action: pickCodeFileAndParse) {
                Label("Open code.txt", systemImage: "doc.text")
            }
            .buttonStyle(GlassButtonStyle(tint: .cyan))
            .disabled(workspace.rootURL == nil)
            .opacity(workspace.rootURL == nil ? 0.4 : 1)

            Button(action: dryRunDiff) {
                Label("Dry-Run (Diff)", systemImage: "doc.badge.gearshape")
            }
            .buttonStyle(GlassButtonStyle(tint: .purple))
            .disabled(blocks.isEmpty || workspace.rootURL == nil)
            .opacity(blocks.isEmpty || workspace.rootURL == nil ? 0.4 : 1)

            Button(role: .destructive, action: applyWrites) {
                Label("Apply (Write)", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(GlassButtonStyle(tint: .pink))
            .disabled(selected.isEmpty || workspace.rootURL == nil)
            .opacity(selected.isEmpty || workspace.rootURL == nil ? 0.35 : 1)

            Spacer()
        }
    }

    private var blocksSection: some View {
        GlassSection(title: blocks.isEmpty ? "" : "Blocks") {
            if blocks.isEmpty {
                ContentPlaceholder(title: "code.txt را باز کن",
                                   subtitle: "فرمت هدر:  --- path/to/file.ext ---")
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                ScrollView {
                    LazyVStack(spacing: 18) {
                        ForEach(blocks) { block in
                            let binding = Binding<Bool>(
                                get: { selected.contains(block.id) },
                                set: { newValue in
                                    if newValue { selected.insert(block.id) } else { selected.remove(block.id) }
                                }
                            )
                            BlockRow(block: block,
                                     diff: diffs[block.id],
                                     isSelected: binding)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 320)
            }
        }
    }

    private var logsSection: some View {
        GlassSection(title: "Logs") {
            if logLines.isEmpty {
                Text("هنوز لاگی ثبت نشده است.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(logLines.indices, id: \.self) { index in
                            Text(logLines[index])
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120, maxHeight: 200)
            }
        }
    }

    // MARK: - Actions

    private func pickCodeFileAndParse() {
        guard workspace.rootURL != nil else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.plainText]
        panel.allowsMultipleSelection = false
        panel.prompt = "Open code.txt"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                blocks = BlockFileParser.parse(text)
                selected = Set(blocks.map { $0.id })
                diffs.removeAll()
                log("Loaded \(blocks.count) block(s) from: \(url.lastPathComponent)")
            } catch {
                log("ERROR reading file: \(error)")
            }
        }
    }

    private func dryRunDiff() {
        guard let root = workspace.rootURL else { return }
        diffs.removeAll()

        for block in blocks {
            let target = root.appendingPathComponent(block.relativePath)
            guard FileGuard.isInsideRoot(target: target, root: root) else {
                log("SKIP (outside root): \(block.relativePath)")
                continue
            }
            let previous = (try? String(contentsOf: target, encoding: .utf8)) ?? ""
            let changes = DiffService.diffLines(old: previous, new: block.content)
            diffs[block.id] = DiffService.stats(changes)
        }
        log("Dry-Run complete. Computed diffs for \(diffs.count) block(s).")
    }

    private func applyWrites() {
        guard let root = workspace.rootURL else { return }
        var applied = 0

        for block in blocks where selected.contains(block.id) {
            do {
                let target = root.appendingPathComponent(block.relativePath)
                guard FileGuard.isInsideRoot(target: target, root: root) else {
                    log("BLOCKED (outside root): \(block.relativePath)")
                    continue
                }
                try BackupService.backupIfExists(root: root, relativePath: block.relativePath)
                try AtomicWriter.writeAtomically(to: target, content: Data(block.content.utf8))
                applied += 1
                log("WROTE: \(block.relativePath)")
            } catch {
                log("ERROR writing \(block.relativePath): \(error)")
            }
        }

        log("Apply complete. Wrote \(applied) file(s).")
        workspace.refresh(showHiddenFiles: false)
    }

    private func log(_ message: String) {
        logLines.append(message)
    }
}

private struct BlockRow: View {
    let block: WriteBlock
    let diff: (added: Int, removed: Int, unchanged: Int)?
    @Binding var isSelected: Bool

    private var badgeText: String {
        guard let diff else { return "No diff yet" }
        return "+\(diff.added)  −\(diff.removed)  =\(diff.unchanged)"
    }

    private var badgeColor: Color {
        guard let diff else { return .white.opacity(0.18) }
        let delta = diff.added + diff.removed
        return delta > 0 ? Color.orange.opacity(0.35) : Color.green.opacity(0.35)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Toggle("", isOn: $isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text(block.relativePath)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white)

                Text(badgeText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(badgeColor, in: Capsule(style: .continuous))
            }

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 14)
    }
}

private struct GlassSection<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title?.isEmpty == false ? title : nil
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            content
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }
}
