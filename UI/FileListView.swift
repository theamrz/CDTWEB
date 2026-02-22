import Foundation
import SwiftUI

struct FileListView: View {
    let items: [FileItem]

    var body: some View {
        List(items) { item in
            FileRow(item: item)
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
}

private struct FileRow: View {
    let item: FileItem

    private var badgeColor: Color {
        item.isDirectory ? Color.cyan.opacity(0.7) : Color.purple.opacity(0.7)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.25))
                    .frame(width: 42, height: 42)
                Image(systemName: item.iconSystemName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.path)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.95))
                if let size = item.size, !item.isDirectory {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer(minLength: 12)

            Text(item.isDirectory ? "Directory" : "File")
                .font(.caption2.bold())
                .textCase(.uppercase)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(badgeColor, in: Capsule(style: .continuous))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 14)
        .textSelection(.enabled)
    }
}
