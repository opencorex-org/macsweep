import SwiftUI

public struct DuplicateFileRow: View {
    public let file: DuplicateFile
    public let fileSize: Int64
    public let onToggle: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { file.isSelected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            Image(systemName: "doc.fill")
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.msLabel)

                    if file.isOriginal {
                        Text("Original")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                    }
                }

                Text(file.url.path)
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(ByteFormatter.format(fileSize))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.msLabel)

                Text(AppDateFormatter.relative(file.modificationDate))
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
            }
        }
        .padding(.vertical, 4)
    }
}
