import SwiftUI
import Combine

@MainActor
public final class StartupItemsViewModel: ObservableObject {
    @Published public private(set) var isLoading: Bool = false
    @Published public var agents: [LaunchAgentInfo] = []

    private let service = LaunchAgentService()

    public init() {}

    public func loadStartupItems() {
        isLoading = true
        self.agents = service.discoverLaunchAgents()
        isLoading = false
    }

    public func toggleAgent(_ agent: LaunchAgentInfo) {
        // Toggle agent plist 'Disabled' field
        guard let data = try? Data(contentsOf: agent.url),
              var plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
            return
        }

        let newDisabled = agent.isEnabled
        plist["Disabled"] = newDisabled

        if let newData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
            try? newData.write(to: agent.url)
        }

        loadStartupItems()
    }
}
