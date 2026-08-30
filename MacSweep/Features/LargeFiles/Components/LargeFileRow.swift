import SwiftUI

public struct LargeFileRow: View {
    public let file: LargeFile
    public let onToggle: () -> Void
    public let onOpen: () -> Void
    public let onReveal: () -> Void

    public init(
        file: LargeFile,
        onToggle: @escaping () -> Void,
        onOpen: @escaping () -> Void,
        onReveal: @escaping () -> Void
    ) {
        self.file = file
        self.onToggle = onToggle
        self.onOpen = onOpen
        self.onReveal = onReveal
    }

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

                HStack(spacing: 6) {
                    Text(file.fileType)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(4)

                    Text(file.directoryPath)
                        .font(.system(size: 10))
                        .foregroundColor(.msSecondaryLabel)
                        .lineLimit(1)
                }
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

            Menu {
                Button("Open", systemImage: "arrow.up.forward.app", action: onOpen)
                Button("Show in Finder", systemImage: "folder", action: onReveal)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 15))
                    .foregroundColor(.msSecondaryLabel)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.vertical, 6)
    }
}
