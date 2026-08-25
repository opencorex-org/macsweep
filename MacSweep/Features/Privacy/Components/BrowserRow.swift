import SwiftUI

public struct BrowserRow: View {
    public let browserName: String
    public let iconName: String
    public let totalSize: Int64

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: iconName)
                    .font(.system(size: 15))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(browserName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.msLabel)
            }

            Spacer()

            Text(ByteFormatter.format(totalSize))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.msLabel)
        }
        .padding(10)
        .background(Color.msSecondaryBackground)
        .cornerRadius(8)
    }
}
