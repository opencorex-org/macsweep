import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public private(set) var diskSpace: DiskSpace?
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var lastScanResult: ScanResult?
    @Published public private(set) var cleanableBytes: Int64 = 0
    @Published public private(set) var scannedItemsCount: Int = 0
    @Published public private(set) var storageSnapshots: [StorageSnapshot] = []
    @Published public private(set) var highImpactStartupCount: Int = 0

    private let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public func refreshDiskSpace() {
        self.diskSpace = try? environment.diskSpaceService.getDiskSpace()
        if let diskSpace { environment.storageHistoryService.record(diskSpace) }
        storageSnapshots = environment.storageHistoryService.snapshots
        highImpactStartupCount = LaunchAgentService().discoverLaunchAgents().filter { $0.isEnabled && $0.impact == "High" }.count
    }

    public var healthStatus: (String, Color) {
        guard let diskSpace else { return ("Unavailable", .gray) }
        if diskSpace.usedPercentage > 0.9 { return ("Storage Critical", .red) }
        if diskSpace.usedPercentage > 0.8 { return ("Storage Low", .orange) }
        return ("Healthy", .green)
    }

    public func runQuickScan() async {
        guard !isScanning else { return }
        isScanning = true
        let result = await environment.scanEngine.performSmartScan()
        self.lastScanResult = result
        self.cleanableBytes = result.totalBytes
        self.scannedItemsCount = result.items.count
        self.isScanning = false
        refreshDiskSpace()
    }
}
