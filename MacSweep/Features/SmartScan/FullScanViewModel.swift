import SwiftUI
import Combine

@MainActor
public final class FullScanViewModel: ObservableObject {
    @Published public private(set) var isScanning = false
    @Published public private(set) var isPaused = false
    @Published public private(set) var isCleaning = false
    @Published public private(set) var cleanProgress: CleanProgress?
    @Published public private(set) var currentProgress: ScanProgress?
    @Published public private(set) var scanResult: ScanResult?
    @Published public var items: [CleanupItem] = []
    @Published public private(set) var lastCleanResult: CleanResult?

    private let environment: AppEnvironment
    private var scanControl: ScanControl?
    private var scanTask: Task<ScanResult, Never>?
    private var activeScanID: UUID?

    public var totalBytes: Int64 { items.reduce(0) { $0 + $1.size } }
    public var selectedBytes: Int64 { items.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    public var selectedCount: Int { items.filter(\.isSelected).count }

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
        currentProgress = ScanProgress(totalCategoriesCount: 8)
        scanResult = nil
        items = []
        lastCleanResult = nil

        let task = Task { [environment, weak self] in
            await environment.scanEngine.performFullScan(control: control) { progress in
                Task { @MainActor [weak self] in
                    guard self?.activeScanID == scanID, self?.isPaused == false else { return }
                    self?.currentProgress = progress
                }
            }
        }
        scanTask = task
        let result = await task.value
        guard activeScanID == scanID, !control.isCancelled else { return }

        scanResult = result
        items = result.items.map { item in
            var item = item
            item.isSelected = item.risk == .safe
            return item
        }
        isScanning = false
        isPaused = false
        scanTask = nil
        scanControl = nil
        activeScanID = nil
    }

    public func togglePause() {
        guard isScanning, let scanControl else { return }
        if isPaused {
            scanControl.resume()
        } else {
            scanControl.pause()
        }
        isPaused.toggle()
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

    public func selectSafeOnly() {
        for index in items.indices {
            items[index].isSelected = items[index].risk == .safe
        }
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
        guard !isCleaning, !isScanning, selectedCount > 0 else { return }
        isCleaning = true
        let selected = items.filter(\.isSelected)
        let totalSelectedBytes = selected.reduce(0) { $0 + $1.size }

        cleanProgress = CleanProgress(
            currentItemName: selected.first?.displayName ?? "Preparing cleanup…",
            currentItemPath: selected.first?.url.path ?? "",
            currentCategory: selected.first?.category,
            completedItemsCount: 0,
            totalItemsCount: selected.count,
            bytesReclaimed: 0,
            totalBytes: totalSelectedBytes
        )

        let result = await environment.cleanEngine.clean(items: selected) { [weak self] progress in
            Task { @MainActor [weak self] in
                guard self?.isCleaning == true else { return }
                self?.cleanProgress = progress
            }
        }
        lastCleanResult = result
        let failedURLs = Set(result.failures.map(\.url))
        items.removeAll { item in
            item.isSelected && !failedURLs.contains(item.url)
        }
        cleanProgress = nil
        isCleaning = false
    }
}
