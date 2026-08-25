import SwiftUI

public struct StorageRow: View {
    public let node: StorageNode
    public let isSelected: Bool
    public let onSelect: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                .font(.system(size: 14))
                .foregroundColor(node.isDirectory ? .blue : .gray)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(.msLabel)
                    .lineLimit(1)

                if node.isDirectory {
                    Text("\(node.childCount) items")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(node.formattedSize)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.msLabel)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.msAccent.opacity(0.12) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
