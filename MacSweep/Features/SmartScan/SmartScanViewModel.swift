import SwiftUI
import Combine

@MainActor
public final class SmartScanViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public private(set) var currentProgress: ScanProgress?
    @Published public private(set) var scanResult: ScanResult?
    @Published public var items: [CleanupItem] = []
    @Published public var selectedCategory: CleanupCategory?
    @Published public var lastCleanResult: CleanResult?

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

    public func startScan() async {
        guard !isScanning else { return }
        isScanning = true
        scanResult = nil
        items = []
        lastCleanResult = nil

        let result = await environment.scanEngine.performSmartScan { [weak self] progress in
            Task { @MainActor in
                self?.currentProgress = progress
            }
        }

        self.scanResult = result
        self.items = result.items
        self.isScanning = false
    }

    public func toggleItemSelection(_ item: CleanupItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
    }

    public func toggleCategorySelection(_ category: CleanupCategory, isSelected: Bool) {
        for index in items.indices where items[index].category == category {
            items[index].isSelected = isSelected
        }
    }

    public func performCleanup() async {
        guard !isCleaning else { return }
        isCleaning = true
        let selectedItems = items.filter(\.isSelected)
        let cleanResult = await environment.cleanEngine.clean(items: selectedItems)
        self.lastCleanResult = cleanResult

        // Remove cleaned items from local state
        self.items.removeAll { item in
            item.isSelected && !cleanResult.failures.contains(where: { $0.url == item.url })
        }
        self.isCleaning = false
    }
}
