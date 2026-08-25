import SwiftUI

public struct AboutSettings: View {
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.square.fill")
                .font(.system(size: 56))
                .foregroundColor(.msAccent)

            VStack(spacing: 4) {
                Text("MacSweep")
                    .font(.system(size: 20, weight: .bold))

                Text("Version 1.0.0 (Build 1)")
                    .font(.system(size: 12))
                    .foregroundColor(.msSecondaryLabel)
            }

            Text("High-performance macOS system cleaner & optimization suite.")
                .font(.system(size: 13))
                .foregroundColor(.msSecondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
