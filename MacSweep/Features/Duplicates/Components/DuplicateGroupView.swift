import SwiftUI

public struct DuplicateGroupView: View {
    public let group: DuplicateGroup
    public let onToggleFile: (UUID) -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group.files.first?.name ?? "Duplicate Group")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.msLabel)

                Spacer()

                Text("Wasted \(group.formattedWastedSpace)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.msCaution)
            }
            .padding(.bottom, 4)

            ForEach(group.files) { file in
                DuplicateFileRow(file: file, fileSize: group.fileSize) {
                    onToggleFile(file.id)
                }
            }
        }
        .padding(12)
        .background(Color.msSecondaryBackground)
        .cornerRadius(10)
    }
}
