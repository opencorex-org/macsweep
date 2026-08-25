import SwiftUI

public struct ErrorView: View {
    public let title: String
    public let message: String
    public let retryAction: (() -> Void)?

    public init(
        title: String = "An Error Occurred",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.msHighRisk)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.msLabel)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            if let retryAction = retryAction {
                SecondaryButton(title: "Try Again", iconName: "arrow.clockwise", action: retryAction)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
