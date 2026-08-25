import SwiftUI

public struct LargeFileRow: View {
    public let file: LargeFile
    public let onToggle: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { file.isSelected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            Image(systemName: "doc.badge.arrow.up.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.msLabel)
                    .lineLimit(1)

                Text(file.directoryPath)
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(file.formattedSize)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.msLabel)

                Text(file.relativeDate)
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
            }
        }
        .padding(.vertical, 6)
    }
}
