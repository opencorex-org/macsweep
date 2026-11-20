import SwiftUI

public struct WelcomeStep: View {
    public let onNext: () -> Void

    public var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 76, height: 76)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("Your Privacy Comes First")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.msLabel)

                Text("MacSweep analyzes your storage locally. File names, contents, and scan results are never uploaded.")
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 410)
            }

            HStack(spacing: 10) {
                privacyFeature("Local Scanning", icon: "internaldrive.fill")
                privacyFeature("No Uploads", icon: "icloud.slash.fill")
                privacyFeature("You Approve Cleanup", icon: "checkmark.shield.fill")
            }

            PrimaryButton(title: "Review Scan Access", iconName: "arrow.right", action: onNext)
        }
        .padding(32)
    }

    private func privacyFeature(_ title: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.green)
            Text(LocalizedStringKey(title))
                .font(.system(size: 10, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
