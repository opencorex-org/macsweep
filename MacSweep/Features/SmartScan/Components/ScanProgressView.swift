import SwiftUI

public struct ScanProgressView: View {
    public let progress: ScanProgress?
    public let isPaused: Bool
    public let onPauseResume: (() -> Void)?
    public let onStop: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fractionCompleted: Double {
        min(max(progress?.fractionCompleted ?? 0, 0), 1)
    }

    public init(
        progress: ScanProgress?,
        isPaused: Bool = false,
        onPauseResume: (() -> Void)? = nil,
        onStop: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.isPaused = isPaused
        self.onPauseResume = onPauseResume
        self.onStop = onStop
    }

    public var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                    .frame(width: 130, height: 130)

                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || isPaused)) { timeline in
                    Circle()
                        .trim(from: 0.04, to: 0.30)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(reduceMotion ? -90 : rotationAngle(at: timeline.date)))
                }

                Image(systemName: isPaused ? "pause.fill" : (progress?.currentCategory?.iconName ?? "sparkles"))
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(progress?.currentCategory?.tintColor ?? .accentColor)
            }

            VStack(spacing: 12) {
                Text(isPaused ? "Scan Paused" : "Scanning Mac...")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.msLabel)

                if let progress = progress {
                    if let category = progress.currentCategory {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(LocalizedStringKey(category.displayName))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(category.tintColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(category.tintColor.opacity(0.12))
                        .cornerRadius(12)
                    }

                    Text("\(progress.scannedItemsCount) items found so far (\(progress.formattedScannedSize))")
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
                        activeProgressBar
                        .frame(height: 8)

                        HStack {
                            Text("\(progress.completedCategoriesCount) of \(progress.totalCategoriesCount) categories complete")
                            Spacer()
                            Text("\(Int(fractionCompleted * 100))%")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                    }
                    .frame(maxWidth: 520)
                }

                if onPauseResume != nil || onStop != nil {
                    HStack(spacing: 12) {
                        if let onPauseResume {
                            Button(action: onPauseResume) {
                                Label(isPaused ? "Resume" : "Pause", systemImage: isPaused ? "play.fill" : "pause.fill")
                                    .frame(minWidth: 78)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }

                        if let onStop {
                            Button(role: .destructive, action: onStop) {
                                Label("Stop", systemImage: "stop.fill")
                                    .frame(minWidth: 78)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var activeProgressBar: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || isPaused || fractionCompleted >= 1)) { timeline in
            GeometryReader { geometry in
                let completedWidth = geometry.size.width * CGFloat(fractionCompleted)
                let activityWidth = min(max(geometry.size.width * 0.16, 28), 80)
                let travel = max(geometry.size.width - activityWidth, 0)
                let activityOffset = reduceMotion ? completedWidth : travel * CGFloat(activityPhase(at: timeline.date))

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))

                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: completedWidth)

                    if fractionCompleted < 1 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color.accentColor.opacity(0.65), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: activityWidth)
                            .offset(x: min(activityOffset, travel))
                    }
                }
                .clipShape(Capsule())
            }
        }
    }

    private func rotationAngle(at date: Date) -> Double {
        let duration = 1.15
        let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration)
        return (elapsed / duration) * 360 - 90
    }

    private func activityPhase(at date: Date) -> Double {
        let duration = 1.4
        return date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration
    }
}
