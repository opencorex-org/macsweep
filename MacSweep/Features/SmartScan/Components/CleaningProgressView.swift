import SwiftUI

/// Custom animated UI for the cleaning process across Smart Scan, Full Scan, and Developer Cleaner.
public struct CleaningProgressView: View {
    public let progress: CleanProgress?
    public let title: String
    public let subtitle: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseGlow = false
    @State private var sweepRotation: Double = 0

    private var fractionCompleted: Double {
        min(max(progress?.fractionCompleted ?? 0, 0), 1)
    }

    public init(
        progress: CleanProgress?,
        title: String = "Cleaning in Progress…",
        subtitle: String = "Safely removing selected clutter and reclaiming disk space…"
    ) {
        self.progress = progress
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // MARK: - Central Cleaning Ring & Gauge
            ZStack {
                // Soft ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.msSafe.opacity(0.22), Color.msAccent.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 170, height: 170)
                    .scaleEffect(pulseGlow ? 1.08 : 0.95)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                        value: pulseGlow
                    )

                // Background track
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 9)
                    .frame(width: 130, height: 130)

                // Rotating dash halo
                Circle()
                    .stroke(
                        Color.msAccent.opacity(0.25),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 8])
                    )
                    .frame(width: 146, height: 146)
                    .rotationEffect(.degrees(sweepRotation))

                // Progress Arc
                Circle()
                    .trim(from: 0, to: CGFloat(max(fractionCompleted, 0.02)))
                    .stroke(
                        LinearGradient(
                            colors: [Color.msAccent, Color.msSafe],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fractionCompleted)

                // Center Content: Percentage & Cleaning Spark
                VStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.msAccent, Color.msSafe],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(pulseGlow ? 1.1 : 0.95)

                    Text("\(Int(fractionCompleted * 100))%")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.msLabel)
                }
            }

            // MARK: - Status Titles
            VStack(spacing: 8) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.msLabel)

                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
            }

            // MARK: - Current Target Card
            if let p = progress {
                VStack(spacing: 10) {
                    if let category = p.currentCategory {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(LocalizedStringKey(category.displayName))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(category.tintColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(category.tintColor.opacity(0.12), in: Capsule())
                    }

                    Text(p.currentItemName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.msLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 420)

                    if !p.currentItemPath.isEmpty {
                        Text(p.currentItemPath)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.msSecondaryLabel.opacity(0.8))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                            .frame(maxWidth: 460)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .frame(maxWidth: 520)

                // MARK: - Reclaimed Progress Stats
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.msAccent, Color.msSafe],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(fractionCompleted))
                                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: fractionCompleted)
                        }
                    }
                    .frame(height: 7)

                    HStack {
                        Text("Reclaimed \(p.formattedBytesReclaimed) of \(p.formattedTotalBytes)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.msSafe)

                        Spacer()

                        Text("\(p.completedItemsCount) of \(p.totalItemsCount) items")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.msSecondaryLabel)
                    }
                }
                .frame(maxWidth: 520)
            }

            Spacer()

            // MARK: - Safety Footer
            HStack(spacing: 6) {
                Image(systemName: "shield.checkmark.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.msSafe)
                Text("SIP integrity protected • System and critical files remain completely safe")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel.opacity(0.8))
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 40)
        .msCenteredScrollable()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            pulseGlow = true
            if !reduceMotion {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    sweepRotation = 360
                }
            }
        }
    }
}
