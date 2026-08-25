import SwiftUI

public struct ScanSummaryView: View {
    public let result: CleanResult
    public let onScanAgain: () -> Void

    public init(result: CleanResult, onScanAgain: @escaping () -> Void = {}) {
        self.result = result
        self.onScanAgain = onScanAgain
    }

    public var body: some View {
        VStack(spacing: 28) {
            // Hero Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 76, height: 76)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("Mac Storage Optimized!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.msLabel)

                Text("Successfully reclaimed \(ByteFormatter.format(result.totalBytesReclaimed)) of disk space")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)
            }

            // Stat Cards Grid
            HStack(spacing: 16) {
                StatCard(
                    title: "Reclaimed Space",
                    value: ByteFormatter.format(result.totalBytesReclaimed),
                    icon: "sparkles",
                    color: .green
                )

                StatCard(
                    title: "Cleaned Items",
                    value: "\(result.successCount)",
                    icon: "checkmark.shield.fill",
                    color: .blue
                )

                if result.failureCount > 0 {
                    StatCard(
                        title: "Skipped / Failed",
                        value: "\(result.failureCount)",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                }
            }
            .frame(maxWidth: 480)

            // Safety Confirmation Badge
            HStack(spacing: 8) {
                Image(systemName: "shield.badge.checkmark")
                    .foregroundColor(.green)
                Text("Files safely processed. System integrity & SIP fully preserved.")
                    .font(.system(size: 12))
                    .foregroundColor(.msSecondaryLabel)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(8)

            Button(action: onScanAgain) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Scan Again")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 160)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)
            }

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.msLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color.msSecondaryBackground)
        .cornerRadius(10)
    }
}
