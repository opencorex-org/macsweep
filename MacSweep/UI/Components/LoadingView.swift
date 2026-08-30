import SwiftUI

public struct ActivityIndicatorView: View {
    public let size: CGFloat

    public init(size: CGFloat = 30) {
        self.size = size
    }

    public var body: some View {
        TimelineView(.animation) { context in
            Circle()
                .trim(from: 0.08, to: 0.78)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: max(2, size * 0.1), lineCap: .round)
                )
                .rotationEffect(.degrees(context.date.timeIntervalSinceReferenceDate * 240))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Loading")
    }
}

public struct LoadingView: View {
    public let title: String
    public let subtitle: String?

    public init(title: String = "Scanning...", subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 16) {
            ActivityIndicatorView(size: 32)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.msLabel)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
