import SwiftUI

public struct CleanableCard: View {
    public let cleanableBytes: Int64
    public let itemsCount: Int
    public let isScanning: Bool
    public let onScanAction: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 34, height: 34)

                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Cleanable Junk")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.msLabel)

                    Text("System caches & temporary items")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()
            }

            Spacer()

            // Main Stat
            VStack(alignment: .leading, spacing: 4) {
                Text(ByteFormatter.format(cleanableBytes))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.msLabel)

                Text(itemsCount == 0 ? "System is optimized" : "\(itemsCount) items ready for cleanup")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
            }

            // Action Button
            HStack {
                Spacer()
                PrimaryButton(
                    title: isScanning ? "Scanning..." : (cleanableBytes > 0 ? "Scan Again" : "Smart Scan"),
                    iconName: "sparkles",
                    isLoading: isScanning,
                    action: onScanAction
                )
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .cardStyle()
    }
}
