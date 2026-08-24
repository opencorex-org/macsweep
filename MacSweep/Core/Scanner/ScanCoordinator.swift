import Foundation
import OSLog

/// Coordinates the lifecycle of scan operations, managing cancellation and state.
public actor ScanCoordinator {
    private var currentScanTask: Task<ScanResult, Never>?
    private let scanEngine: ScanEngine

    public var isScanning: Bool {
        currentScanTask != nil && currentScanTask?.isCancelled == false
    }

    public init(scanEngine: ScanEngine) {
        self.scanEngine = scanEngine
    }

    /// Starts a Smart Scan, cancelling any in-progress scan first.
    public func startSmartScan(
        progressHandler: @Sendable @escaping (ScanProgress) -> Void
    ) async -> ScanResult {
        cancelCurrentScan()

        let task = Task {
            await scanEngine.performSmartScan(progressHandler: progressHandler)
        }
        currentScanTask = task
        let result = await task.value
        currentScanTask = nil
        return result
    }

    /// Starts a Developer-only scan.
    public func startDeveloperScan() async -> ScanResult {
        cancelCurrentScan()

        let task = Task {
            await scanEngine.performDeveloperScan()
        }
        currentScanTask = task
        let result = await task.value
        currentScanTask = nil
        return result
    }

    /// Cancels any currently running scan.
    public func cancelCurrentScan() {
        currentScanTask?.cancel()
        currentScanTask = nil
        Logger.scanner.info("Scan cancelled")
    }
}
