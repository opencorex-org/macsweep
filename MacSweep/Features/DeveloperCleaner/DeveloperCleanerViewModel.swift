import SwiftUI
import Combine

@MainActor
public final class DeveloperCleanerViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public var items: [CleanupItem] = []

    private let environment: AppEnvironment

    public var selectedBytes: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    public var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    public var selectedCount: Int {
        items.filter(\.isSelected).count
    }

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public func scanDeveloperCaches() async {
        guard !isScanning else { return }
        isScanning = true
        let result = await environment.scanEngine.performDeveloperScan()
        self.items = result.items
        self.isScanning = false
    }

    public func toggleItemSelection(_ item: CleanupItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
    }

    public func cleanSelectedCaches() async {
        guard !isCleaning else { return }
        isCleaning = true
        let selected = items.filter(\.isSelected)
        let result = await environment.cleanEngine.clean(items: selected)

        items.removeAll { item in
            item.isSelected && !result.failures.contains(where: { $0.url == item.url })
        }
        isCleaning = false
    }
}
