import SwiftUI
import Combine

@MainActor
public final class OptimiseViewModel: ObservableObject {
    @Published public private(set) var isScanning = false
    @Published public private(set) var isCleaning = false
    @Published public private(set) var scanProgress: ScanProgress?
    @Published public private(set) var cleanProgress: CleanProgress?
    @Published public private(set) var hasAnalysed = false
    @Published public private(set) var lastCleanResult: CleanResult?
    @Published public private(set) var verifiedBytesFreed: Int64?
    @Published public var items: [CleanupItem] = []

    private let environment: AppEnvironment
    private var scanControl: ScanControl?
    private var scanTask: Task<ScanResult, Never>?

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public var selectedItems: [CleanupItem] { items.filter(\.isSelected) }
    public var selectedCount: Int { selectedItems.count }
    public var selectedBytes: Int64 { selectedItems.reduce(0) { $0 + $1.size } }
    public var reclaimableBytes: Int64 { items.reduce(0) { $0 + $1.size } }
    public var categoryCount: Int { Set(items.map(\.category)).count }

    public func analyse() async {
        guard !isScanning, !isCleaning else { return }
        let control = ScanControl()
        scanControl = control
        isScanning = true
        hasAnalysed = false
        lastCleanResult = nil
        verifiedBytesFreed = nil
        items = []
        scanProgress = ScanProgress(totalCategoriesCount: CleanupCategory.allCases.count)

        let task = Task { [environment, weak self] in
            await environment.scanEngine.performFullScan(control: control) { progress in
                Task { @MainActor [weak self] in
                    guard self?.isScanning == true else { return }
                    self?.scanProgress = progress
                }
            }
        }
        scanTask = task
        let result = await task.value
        guard !control.isCancelled else { return }

        let recommendations = environment.exclusionService.filter(result.items)
            .filter { $0.risk == .safe && !environment.ignoreListStore.contains($0) }
            .map { item in
                var item = item
                item.isSelected = true
                return item
            }
        items = recommendations
        environment.activityLogStore.recordScan(
            ScanResult(
                items: recommendations,
                duration: result.duration,
                scannedCategories: Array(Set(recommendations.map(\.category)))
            ),
            title: "Recommendations analysis completed"
        )
        hasAnalysed = true
        finishScan()
    }

    public func stopScan() {
        scanControl?.cancel()
        scanTask?.cancel()
        finishScan()
    }

    public func selectAll() {
        for index in items.indices { items[index].isSelected = true }
    }

    public func deselectAll() {
        for index in items.indices { items[index].isSelected = false }
    }

    public func toggle(_ item: CleanupItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isSelected.toggle()
    }

    public func setSelection(for category: CleanupCategory, isSelected: Bool) {
        for index in items.indices where items[index].category == category {
            items[index].isSelected = isSelected
        }
    }

    public func cleanSelected() async {
        let selected = selectedItems
        guard !isCleaning, !isScanning, !selected.isEmpty else { return }
        isCleaning = true
        let availableBefore = try? environment.diskSpaceService.getDiskSpace().availableCapacity
        cleanProgress = CleanProgress(
            currentItemName: selected.first?.displayName ?? "Preparing optimisation…",
            currentItemPath: selected.first?.url.path ?? "",
            currentCategory: selected.first?.category,
            completedItemsCount: 0,
            totalItemsCount: selected.count,
            bytesReclaimed: 0,
            totalBytes: selectedBytes
        )

        let result = await environment.cleanEngine.clean(items: selected) { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.cleanProgress = progress
            }
        }
        lastCleanResult = result
        if let before = availableBefore,
           let after = try? environment.diskSpaceService.getDiskSpace().availableCapacity {
            verifiedBytesFreed = max(0, after - before)
        }
        environment.activityLogStore.recordCleanup(result, title: "Recommended cleanup completed")

        let failedURLs = Set(result.failures.map(\.url))
        items.removeAll { $0.isSelected && !failedURLs.contains($0.url) }
        cleanProgress = nil
        isCleaning = false
    }

    private func finishScan() {
        scanTask = nil
        scanControl = nil
        scanProgress = nil
        isScanning = false
    }
}
