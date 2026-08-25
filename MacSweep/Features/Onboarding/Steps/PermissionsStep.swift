import SwiftUI

public struct PermissionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    public let onNext: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundColor(.msAccent)

            VStack(spacing: 6) {
                Text("Full Disk Access Required")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.msLabel)

                Text("To clean system caches, user logs, and developer artifacts, MacSweep needs Full Disk Access permission.")
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            SecondaryButton(title: "Grant Permission in System Settings", iconName: "lock.fill") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FullDisk") {
                    NSWorkspace.shared.open(url)
                }
            }

            HStack(spacing: 12) {
                SecondaryButton(title: "Check Status") {
                    viewModel.checkPermissions()
                }

                PrimaryButton(title: "Continue", iconName: "arrow.right", action: onNext)
            }
            .padding(.top, 8)
        }
        .padding(32)
    }
}
