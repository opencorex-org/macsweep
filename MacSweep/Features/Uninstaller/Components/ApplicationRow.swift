import SwiftUI

public struct ApplicationRow: View {
    public let app: ApplicationInfo
    public let isSelected: Bool
    public let onSelect: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 36, height: 36)

                Image(systemName: "app.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.msAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(.msLabel)

                Text(app.version.isEmpty ? app.bundleIdentifier : "v\(app.version)")
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
