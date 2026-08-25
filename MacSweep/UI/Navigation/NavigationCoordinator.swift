import SwiftUI
import Combine

@MainActor
public final class NavigationCoordinator: ObservableObject {
    @Published public var selectedItem: NavigationItem? = .dashboard
    @Published public var showOnboarding: Bool = false

    public init(selectedItem: NavigationItem? = .dashboard) {
        self.selectedItem = selectedItem
    }

    public func navigate(to item: NavigationItem) {
        self.selectedItem = item
    }
}
