import SwiftUI

public struct DeveloperCacheCard: View {
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let tintColor: Color
    public let size: Int64
    public let count: Int

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tintColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(tintColor)
                }

                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.msLabel)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ByteFormatter.format(size))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.msLabel)

                Text("\(count) items • \(subtitle)")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }
        }
        .cardStyle()
    }
}
