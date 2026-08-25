import SwiftUI

public struct WelcomeStep: View {
    public let onNext: () -> Void

    public var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.msAccent.opacity(0.12))
                    .frame(width: 90, height: 90)

                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.msAccent)
            }

            VStack(spacing: 8) {
                Text("Welcome to MacSweep")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.msLabel)

                Text("Optimize system performance, clean junk files, analyze disk usage, and manage developer caches.")
                    .font(.system(size: 14))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            PrimaryButton(title: "Get Started", iconName: "arrow.right", action: onNext)
                .padding(.top, 8)
        }
        .padding(32)
    }
}
