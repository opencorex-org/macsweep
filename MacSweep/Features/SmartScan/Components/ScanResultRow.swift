import SwiftUI

public struct ScanResultRow: View {
    public let item: CleanupItem
    public let onToggle: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundColor(item.isDirectory ? .blue : .gray)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.msLabel)
                    .lineLimit(1)

                Text(item.url.path)
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedSize)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.msLabel)

                Text(item.risk.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(item.risk.color)
            }
        }
        .padding(.vertical, 4)
    }
}

public extension CleanupRisk {
    var color: Color {
        switch self {
        case .safe: return .green
        case .caution: return .orange
        case .high: return .red
        }
    }
}
