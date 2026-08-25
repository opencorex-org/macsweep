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
        // Simple FDA check by attempting to access a restricted directory
        let fdaPath = "/Library/Preferences/com.apple.TimeMachine.plist"
        self.hasFullDiskAccess = FileManager.default.isReadableFile(atPath: fdaPath)
    }

    public func nextStep() {
        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }
}
