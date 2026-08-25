import SwiftUI

public struct CompleteStep: View {
    public let onFinish: () -> Void

    public var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.msSafe.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.msSafe)
            }

            VStack(spacing: 8) {
                Text("Setup Complete!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.msLabel)

                Text("You are ready to optimize and clean your Mac.")
                    .font(.system(size: 14))
                    .foregroundColor(.msSecondaryLabel)
            }

            PrimaryButton(title: "Open Dashboard", iconName: "gauge.medium", action: onFinish)
                .padding(.top, 8)
        }
        .padding(32)
    }
}
