import SwiftUI
import AppKit

public struct ApplicationIconView: View {
    public let bundleURL: URL
    public let size: CGFloat

    public init(bundleURL: URL, size: CGFloat) {
        self.bundleURL = bundleURL
        self.size = size
    }

    public var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: bundleURL.path))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

public struct ApplicationRow: View {
    public let app: ApplicationInfo
    public let isSelected: Bool
    public let onSelect: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            ApplicationIconView(bundleURL: app.bundleURL, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(.msLabel)

                Text(app.version.isEmpty ? app.bundleIdentifier : "v\(app.version) • \(app.leftovers.count) leftover\(app.leftovers.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            Text(app.formattedTotalSize)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.msLabel)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.msAccent.opacity(0.12) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
