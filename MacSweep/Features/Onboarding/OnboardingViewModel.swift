import SwiftUI
import Combine

public enum OnboardingStep: Int, CaseIterable {
    case welcome
    case permissions
    case complete
}

@MainActor
public final class OnboardingViewModel: ObservableObject {
    @Published public var currentStep: OnboardingStep = .welcome
    @Published public var hasFullDiskAccess: Bool = false

    public init() {}

    public func checkPermissions() {
        hasFullDiskAccess = FullDiskAccessManager.shared.hasFullDiskAccess
    }

    public func nextStep() {
        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }
}
