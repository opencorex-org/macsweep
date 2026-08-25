import SwiftUI

public struct EmptyStateView: View {
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let buttonTitle: String?
    public let buttonAction: (() -> Void)?

    public init(
        title: String,
        subtitle: String,
        iconName: String = "tray",
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.msSecondaryLabel)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.msLabel)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                PrimaryButton(title: buttonTitle, action: buttonAction)
                    .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
