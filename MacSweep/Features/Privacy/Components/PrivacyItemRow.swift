import SwiftUI

public struct PrivacyItemRow: View {
    public let item: PrivacyItem
    public let onToggle: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            Image(systemName: item.iconName)
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(item.browserName) — \(item.title)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.msLabel)

                Text(item.path.path)
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            Text(ByteFormatter.format(item.size))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.msLabel)
        }
        .padding(.vertical, 6)
    }
}
