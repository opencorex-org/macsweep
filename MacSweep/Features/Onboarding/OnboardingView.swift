import SwiftUI

public struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    public let onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack {
            switch viewModel.currentStep {
            case .welcome:
                WelcomeStep {
                    viewModel.nextStep()
                }
            case .permissions:
                PermissionsStep(viewModel: viewModel) {
                    viewModel.nextStep()
                }
            case .complete:
                CompleteStep {
                    onDismiss()
                }
            }
        }
        .frame(width: 520, height: 400)
        .background(Color.msBackground)
    }
}
