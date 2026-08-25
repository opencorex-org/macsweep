import Foundation
import OSLog
import os

/// Central scan engine that orchestrates concurrent scanner execution,
/// safety validation, and result aggregation.
public actor ScanEngine {
    private let safetyValidator: SafetyValidator
    private let cacheScanner = CacheScanner()
    private let logScanner = LogScanner()
    private let trashScanner = TrashScanner()
    private let xcodeScanner = XcodeScanner()
    private let gradleScanner = GradleScanner()
    private let nodeScanner = NodeScanner()
    private let homebrewScanner = HomebrewScanner()
    private let dockerScanner = DockerScanner()

    public init(safetyValidator: SafetyValidator) {
        self.safetyValidator = safetyValidator
    }

    /// Runs a full Smart Scan across all categories concurrently.
    /// - Parameter progressHandler: Called with progress updates during scanning.
    /// - Returns: A complete `ScanResult` with safety-validated items.
    public func performSmartScan(
        progressHandler: @escaping @Sendable (ScanProgress) -> Void = { _ in }
    ) async -> ScanResult {
        let startTime = Date()
        Logger.scanner.info("Starting Smart Scan")

        var allItems: [CleanupItem] = []
        let runningBytes = OSAllocatedUnfairLock(initialState: Int64(0))
        let runningCount = OSAllocatedUnfairLock(initialState: 0)

        let makeProgress: @Sendable (CleanupCategory, String) -> Void = { category, path in
            let bytes = runningBytes.withLock { $0 }
            let count = runningCount.withLock { $0 }
            progressHandler(ScanProgress(
                currentCategory: category,
                currentPath: path,
                scannedBytes: bytes,
                scannedItemsCount: count
            ))
        }

        // Run all scanners concurrently using a TaskGroup
        await withTaskGroup(of: [ScanItem].self) { group in
            group.addTask { await self.cacheScanner.scan { makeProgress(.systemCache, $0) } }
            group.addTask { await self.logScanner.scan { makeProgress(.userLogs, $0) } }
            group.addTask { await self.trashScanner.scan { makeProgress(.trash, $0) } }
            group.addTask { await self.xcodeScanner.scan { makeProgress(.developerXcode, $0) } }
            group.addTask { await self.gradleScanner.scan { makeProgress(.developerGradle, $0) } }
            group.addTask { await self.nodeScanner.scan { makeProgress(.developerNode, $0) } }
            group.addTask { await self.homebrewScanner.scan { makeProgress(.developerHomebrew, $0) } }
            group.addTask { await self.dockerScanner.scan { makeProgress(.developerDocker, $0) } }

            for await scanItems in group {
                var newValidItems: [CleanupItem] = []
                for item in scanItems {
                    let result = safetyValidator.validate(item.url)
                    switch result {
                    case .approved:
                        newValidItems.append(item.toCleanupItem())
                    case .rejected(let reason):
                        Logger.safety.debug("Rejected: \(item.url.path, privacy: .private) — \(reason)")
                    case .skipped(let reason):
                        Logger.safety.debug("Skipped: \(item.url.path, privacy: .private) — \(reason)")
                    }
                }

                let addedBytes = newValidItems.reduce(0) { $0 + $1.size }
                let addedCount = newValidItems.count

                runningBytes.withLock { $0 += addedBytes }
                runningCount.withLock { $0 += addedCount }

                allItems.append(contentsOf: newValidItems)
            }
        }

        // Sort items by size descending
        allItems.sort { $0.size > $1.size }

        let duration = Date().timeIntervalSince(startTime)
        let totalBytes = allItems.reduce(0) { $0 + $1.size }

        Logger.scanner.info("Smart Scan complete: \(allItems.count) items, \(ByteFormatter.format(totalBytes)), \(String(format: "%.1f", duration))s")

        progressHandler(ScanProgress.completed(totalBytes: totalBytes, totalItems: allItems.count))

        return ScanResult(
            items: allItems,
            duration: duration,
            scannedCategories: Array(Set(allItems.map(\.category)))
        )
    }

    /// Runs a developer-only scan targeting dev tool caches.
    public func performDeveloperScan() async -> ScanResult {
        let startTime = Date()
        var allItems: [CleanupItem] = []

        await withTaskGroup(of: [ScanItem].self) { group in
            group.addTask { await self.xcodeScanner.scan() }
            group.addTask { await self.gradleScanner.scan() }
            group.addTask { await self.nodeScanner.scan() }
            group.addTask { await self.homebrewScanner.scan() }
            group.addTask { await self.dockerScanner.scan() }

            for await scanItems in group {
                for item in scanItems {
                    if safetyValidator.validate(item.url) == .approved {
                        allItems.append(item.toCleanupItem())
                    }
                }
            }
        }

        allItems.sort { $0.size > $1.size }
        let duration = Date().timeIntervalSince(startTime)

        return ScanResult(
            items: allItems,
            duration: duration,
            scannedCategories: Array(Set(allItems.map(\.category)))
        )
    }
}
