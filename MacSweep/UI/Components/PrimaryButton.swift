import SwiftUI

public struct PrimaryButton: View {
    public let title: String
    public let iconName: String?
    public let isLoading: Bool
    public let action: () -> Void
    @State private var isSpinnerRotating = false

    public init(
        title: String,
        iconName: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                        .rotationEffect(.degrees(isSpinnerRotating ? 360 : 0))
                        .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinnerRotating)
                        .onAppear { isSpinnerRotating = true }
                        .onDisappear { isSpinnerRotating = false }
                } else if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 32)
            .background(Color.msAccent)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .hoverEffect(scale: 1.02)
    }
}
