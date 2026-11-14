import SwiftUI

public struct ScanSummaryView: View {
    public let result: CleanResult
    public let verifiedBytesFreed: Int64?
    public let onScanAgain: () -> Void

    public init(result: CleanResult, verifiedBytesFreed: Int64? = nil, onScanAgain: @escaping () -> Void = {}) {
        self.result = result
        self.verifiedBytesFreed = verifiedBytesFreed
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

                Text("Removed \(ByteFormatter.format(result.totalBytesReclaimed)) of cache and junk data")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)
            }

            // Stat Cards Grid
            HStack(spacing: 16) {
                StatCard(
                    title: "Removed Data",
                    value: ByteFormatter.format(result.totalBytesReclaimed),
                    icon: "sparkles",
                    color: .green
                )

                if let verifiedBytesFreed {
                    StatCard(
                        title: "Verified Free Space",
                        value: ByteFormatter.format(verifiedBytesFreed),
                        icon: "checkmark.circle",
                        color: .teal
                    )
                }

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

            if !result.failures.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Items That Need Attention", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.msCaution)

                    ForEach(Array(result.failures.prefix(3).enumerated()), id: \.offset) { _, failure in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(failure.url.lastPathComponent)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.msLabel)
                                .lineLimit(1)
                            Text(failure.error ?? "The item could not be removed")
                                .font(.system(size: 10))
                                .foregroundColor(.msSecondaryLabel)
                                .lineLimit(2)
                        }
                    }

                    if result.failures.count > 3 {
                        Text("And \(result.failures.count - 3) more…")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.msSecondaryLabel)
                    }
                }
                .padding(12)
                .frame(maxWidth: 480, alignment: .leading)
                .background(Color.msCaution.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.msAccent)
                Text("macOS may keep removed cache storage reserved while an app still has files open. Quit affected apps—or restart your Mac—then scan again to verify the released space.")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: 480)
            .background(Color.msAccent.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

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
