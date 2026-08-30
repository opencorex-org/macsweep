import SwiftUI
import Combine

@MainActor
public final class DeveloperCleanerViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public private(set) var currentProgress: ScanProgress?
    @Published public private(set) var scanResult: ScanResult?
    @Published public var items: [CleanupItem] = []
    @Published public private(set) var lastCleanResult: CleanResult?

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
        currentProgress = ScanProgress(totalCategoriesCount: 5)
        scanResult = nil
        items = []
        lastCleanResult = nil

        let startTime = Date()
        let result = await environment.scanEngine.performDeveloperScan { [weak self] progress in
            Task { @MainActor in
                self?.currentProgress = progress
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 2.5 {
            try? await Task.sleep(nanoseconds: UInt64((2.5 - elapsed) * 1_000_000_000))
        }

        self.scanResult = result
        self.items = result.items
        self.isScanning = false
    }

    public func selectAll() {
        for index in items.indices {
            items[index].isSelected = true
        }
    }

    public func selectSafeOnly() {
        for index in items.indices {
            items[index].isSelected = items[index].risk == .safe
        }
    }

    public func deselectAll() {
        for index in items.indices {
            items[index].isSelected = false
        }
    }

    public func toggleItemSelection(_ item: CleanupItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
    }

    public func cleanSelectedCaches() async {
        guard !isCleaning, selectedCount > 0 else { return }
        isCleaning = true
        let selected = items.filter(\.isSelected)
        let result = await environment.cleanEngine.clean(items: selected)

        lastCleanResult = result

        items.removeAll { item in
            item.isSelected && !result.failures.contains(where: { $0.url == item.url })
        }
        isCleaning = false
    }
}
