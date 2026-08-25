import SwiftUI

public struct ScanProgressView: View {
    public let progress: ScanProgress?

    public var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 8)
                    .frame(width: 120, height: 120)

                ProgressView()
                    .scaleEffect(1.5)
                    .controlSize(.large)
            }

            VStack(spacing: 8) {
                Text("Scanning Mac...")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.msLabel)

                if let progress = progress {
                    Text("\(progress.scannedItemsCount) items scanned (\(progress.formattedScannedSize))")
                        .font(.system(size: 13))
                        .foregroundColor(.msSecondaryLabel)

                    if !progress.currentPath.isEmpty {
                        Text(progress.currentPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.msSecondaryLabel)
                            .lineLimit(1)
                            .frame(maxWidth: 400)
                    }
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
