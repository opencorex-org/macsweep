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
        currentProgress = ScanProgress(totalCategoriesCount: 8)
        scanResult = nil
        items = []
        lastCleanResult = nil

        let startTime = Date()

        let result = await environment.scanEngine.performSmartScan { [weak self] progress in
            Task { @MainActor in
                self?.currentProgress = progress
            }
        }

        // Enforce minimum scan pacing (2.5s) so live scanning UI feedback is smooth and visible
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 2.5 {
            let delayNano = UInt64((2.5 - elapsed) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayNano)
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

    public func deselectAll() {
        for index in items.indices {
            items[index].isSelected = false
        }
    }

    public func selectSafeOnly() {
        for index in items.indices {
            items[index].isSelected = (items[index].risk == .safe)
        }
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
