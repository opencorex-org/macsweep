import SwiftUI

public struct PermissionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    public let onNext: () -> Void

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.hasFullDiskAccess ? "checkmark.shield.fill" : "externaldrive.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(viewModel.hasFullDiskAccess ? .green : .msAccent)

            VStack(spacing: 6) {
                Text(viewModel.hasFullDiskAccess ? "Full Disk Access Enabled" : "Choose Scan Access")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.msLabel)

                Text(viewModel.hasFullDiskAccess
                     ? "MacSweep can inspect protected cache and log locations for more complete results."
                     : "MacSweep works with limited access. Full Disk Access improves coverage, but macOS only allows you to grant it in System Settings.")
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            if viewModel.hasFullDiskAccess {
                PrimaryButton(title: "Continue", iconName: "arrow.right", action: onNext)
            } else {
                VStack(spacing: 10) {
                    PrimaryButton(title: "Continue with Limited Access", iconName: "arrow.right", action: onNext)

                    HStack(spacing: 10) {
                        SecondaryButton(title: "Open Privacy & Security", iconName: "lock.fill") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FullDisk") {
                                NSWorkspace.shared.open(url)
                            }
                        }

                        SecondaryButton(title: "Check Status", iconName: "arrow.clockwise") {
                            viewModel.checkPermissions()
                        }
                    }
                }
            }
        }
        .padding(32)
        .onAppear {
            viewModel.checkPermissions()
        }
    }
}
