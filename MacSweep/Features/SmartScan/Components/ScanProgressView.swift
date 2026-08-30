import SwiftUI

public struct ScanProgressView: View {
    public let progress: ScanProgress?

    private var fractionCompleted: Double {
        min(max(progress?.fractionCompleted ?? 0, 0), 1)
    }

    public init(progress: ScanProgress?) {
        self.progress = progress
    }

    public var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(progress == nil ? 0 : 360))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: progress != nil)

                Image(systemName: progress?.currentCategory?.iconName ?? "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(progress?.currentCategory?.tintColor ?? .accentColor)
            }

            VStack(spacing: 12) {
                Text("Scanning Mac...")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.msLabel)

                if let progress = progress {
                    if let category = progress.currentCategory {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(category.displayName)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(category.tintColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(category.tintColor.opacity(0.12))
                        .cornerRadius(12)
                    }

                    Text("\(progress.scannedItemsCount) items found (\(progress.formattedScannedSize))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.msSecondaryLabel)

                    if !progress.currentPath.isEmpty {
                        Text(progress.currentPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.msSecondaryLabel.opacity(0.85))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(6)
                            .frame(maxWidth: 520)
                    }

                    VStack(spacing: 7) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                Capsule()
                                    .fill(Color.accentColor)
                                    .frame(width: geometry.size.width * CGFloat(fractionCompleted))
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("Analyzing categories")
                            Spacer()
                            Text("\(Int(fractionCompleted * 100))%")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                    }
                    .frame(maxWidth: 520)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
