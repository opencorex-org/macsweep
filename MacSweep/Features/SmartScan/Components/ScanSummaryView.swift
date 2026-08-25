import SwiftUI

public struct ScanSummaryView: View {
    public let result: CleanResult

    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.msSafe.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.msSafe)
            }

            VStack(spacing: 6) {
                Text("Cleanup Complete!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.msLabel)

                Text("Successfully reclaimed \(ByteFormatter.format(result.totalBytesReclaimed))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)
            }

            HStack(spacing: 24) {
                VStack {
                    Text("\(result.successCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msSafe)
                    Text("Cleaned")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                }

                if result.failureCount > 0 {
                    VStack {
                        Text("\(result.failureCount)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.msHighRisk)
                        Text("Failed")
                            .font(.system(size: 11))
                            .foregroundColor(.msSecondaryLabel)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.msSecondaryBackground)
            .cornerRadius(10)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
