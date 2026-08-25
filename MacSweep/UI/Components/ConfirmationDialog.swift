import SwiftUI

public struct ConfirmationDialog: View {
    public let title: String
    public let message: String
    public let confirmTitle: String
    public let cancelTitle: String
    public let isDestructive: Bool
    public let onConfirm: () -> Void
    public let onCancel: () -> Void

    public init(
        title: String,
        message: String,
        confirmTitle: String = "Clean",
        cancelTitle: String = "Cancel",
        isDestructive: Bool = true,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isDestructive ? "trash.fill" : "info.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isDestructive ? .msHighRisk : .msAccent)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.msLabel)

                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.msSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                Spacer()

                SecondaryButton(title: cancelTitle, action: onCancel)

                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(isDestructive ? Color.msHighRisk : Color.msAccent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(Color.msBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}
