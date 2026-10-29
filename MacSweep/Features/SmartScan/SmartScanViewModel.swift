import SwiftUI
import Combine

@MainActor
public final class SmartScanViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isPaused: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public private(set) var cleanProgress: CleanProgress?
    @Published public private(set) var currentProgress: ScanProgress?
    @Published public private(set) var scanResult: ScanResult?
    @Published public var items: [CleanupItem] = []
    @Published public var selectedCategory: CleanupCategory?
    @Published public var lastCleanResult: CleanResult?

    private let environment: AppEnvironment
    private var scanControl: ScanControl?
    private var scanTask: Task<ScanResult, Never>?
    private var activeScanID: UUID?

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
        guard !isScanning, !isCleaning else { return }
        let scanID = UUID()
        let control = ScanControl()
        activeScanID = scanID
        scanControl = control
        isScanning = true
        isPaused = false
        currentProgress = ScanProgress(totalCategoriesCount: 3)
        scanResult = nil
        items = []
        lastCleanResult = nil

        let task = Task { [environment, weak self] in
            await environment.scanEngine.performSmartScan(control: control) { progress in
                Task { @MainActor [weak self] in
                    guard self?.activeScanID == scanID, self?.isPaused == false else { return }
                    self?.currentProgress = progress
                }
            }
        }
        scanTask = task
        let result = await task.value
        guard activeScanID == scanID, !control.isCancelled else { return }

        self.scanResult = result
        self.items = result.items
        self.isScanning = false
        self.isPaused = false
        self.scanTask = nil
        self.scanControl = nil
        self.activeScanID = nil
    }

    public func togglePause() {
        guard isScanning, let scanControl else { return }
        if isPaused {
            scanControl.resume()
            isPaused = false
        } else {
            scanControl.pause()
            isPaused = true
        }
    }

    public func stopScan() {
        guard isScanning else { return }
        scanControl?.cancel()
        scanTask?.cancel()
        scanTask = nil
        scanControl = nil
        activeScanID = nil
        isPaused = false
        isScanning = false
        currentProgress = nil
        scanResult = nil
        items = []
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
        guard !isCleaning, !isScanning, selectedCount > 0 else { return }
        isCleaning = true
        let selectedItems = items.filter(\.isSelected)
        let totalSelectedBytes = selectedItems.reduce(0) { $0 + $1.size }

        cleanProgress = CleanProgress(
            currentItemName: selectedItems.first?.displayName ?? "Preparing cleanup…",
            currentItemPath: selectedItems.first?.url.path ?? "",
            currentCategory: selectedItems.first?.category,
            completedItemsCount: 0,
            totalItemsCount: selectedItems.count,
            bytesReclaimed: 0,
            totalBytes: totalSelectedBytes
        )

        let cleanResult = await environment.cleanEngine.clean(items: selectedItems) { [weak self] progress in
            Task { @MainActor [weak self] in
                guard self?.isCleaning == true else { return }
                self?.cleanProgress = progress
            }
        }
        self.lastCleanResult = cleanResult

        // Remove cleaned items from local state
        let failedURLs = Set(cleanResult.failures.map(\.url))
        self.items.removeAll { item in
            item.isSelected && !failedURLs.contains(item.url)
        }
        self.cleanProgress = nil
        self.isCleaning = false
    }
}
