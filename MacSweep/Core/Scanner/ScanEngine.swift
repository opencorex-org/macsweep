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

    /// Runs a quick Smart Scan across common system cleanup categories.
    /// - Parameter progressHandler: Called with progress updates during scanning.
    /// - Returns: A complete `ScanResult` with safety-validated items.
    public func performSmartScan(
        control: ScanControl? = nil,
        progressHandler: @escaping @Sendable (ScanProgress) -> Void = { _ in }
    ) async -> ScanResult {
        let startTime = Date()
        var allItems: [CleanupItem] = []
        let runningBytes = OSAllocatedUnfairLock(initialState: Int64(0))
        let runningCount = OSAllocatedUnfairLock(initialState: 0)
        let completedCategories = OSAllocatedUnfairLock(initialState: 0)
        let totalCategories = 3

        let lastProgressTime = OSAllocatedUnfairLock(initialState: ContinuousClock.now)
        let makeProgress: @Sendable (CleanupCategory, String) -> Void = { category, path in
            // Bound UI work across all concurrent scanners to ten updates per second.
            let shouldReport = lastProgressTime.withLock { last in
                let now = ContinuousClock.now
                guard now - last >= .milliseconds(100) else { return false }
                last = now
                return true
            }
            guard shouldReport, !Task.isCancelled, control?.isCancelled != true else { return }
            progressHandler(ScanProgress(
                currentCategory: category,
                currentPath: path,
                scannedBytes: runningBytes.withLock { $0 },
                scannedItemsCount: runningCount.withLock { $0 },
                completedCategoriesCount: completedCategories.withLock { $0 },
                totalCategoriesCount: totalCategories
            ))
        }

        await withTaskGroup(of: [ScanItem].self) { group in
            group.addTask { await self.cacheScanner.scan(onProgress: { makeProgress(.systemCache, $0) }, control: control) }
            group.addTask { await self.logScanner.scan(onProgress: { makeProgress(.userLogs, $0) }, control: control) }
            group.addTask { await self.trashScanner.scan(onProgress: { makeProgress(.trash, $0) }, control: control) }

            for await scanItems in group {
                if Task.isCancelled || control?.isCancelled == true {
                    group.cancelAll()
                    break
                }
                let validItems = scanItems.compactMap { item -> CleanupItem? in
                    guard safetyValidator.validate(item.url) == .approved else { return nil }
                    return item.toCleanupItem()
                }
                let addedBytes = validItems.reduce(0) { $0 + $1.size }
                runningBytes.withLock { $0 += addedBytes }
                runningCount.withLock { $0 += validItems.count }
                let completed = completedCategories.withLock {
                    $0 += 1
                    return $0
                }
                allItems.append(contentsOf: validItems)
                progressHandler(ScanProgress(
                    scannedBytes: runningBytes.withLock { $0 },
                    scannedItemsCount: runningCount.withLock { $0 },
                    completedCategoriesCount: completed,
                    totalCategoriesCount: totalCategories
                ))
            }
        }

        allItems.sort { $0.size > $1.size }
        let totalBytes = allItems.reduce(0) { $0 + $1.size }
        if !Task.isCancelled && control?.isCancelled != true {
            progressHandler(.completed(totalBytes: totalBytes, totalItems: allItems.count, totalCategories: totalCategories))
        }
        return ScanResult(
            items: allItems,
            duration: Date().timeIntervalSince(startTime),
            scannedCategories: Array(Set(allItems.map(\.category)))
        )
    }

    /// Runs a comprehensive scan across system and developer cleanup categories.
    public func performFullScan(
        control: ScanControl? = nil,
        progressHandler: @escaping @Sendable (ScanProgress) -> Void = { _ in }
    ) async -> ScanResult {
        let startTime = Date()
        Logger.scanner.info("Starting Full Scan")

        var allItems: [CleanupItem] = []
        let runningBytes = OSAllocatedUnfairLock(initialState: Int64(0))
        let runningCount = OSAllocatedUnfairLock(initialState: 0)
        let completedCategories = OSAllocatedUnfairLock(initialState: 0)
        let totalCategories = 8

        let lastProgressTime = OSAllocatedUnfairLock(initialState: ContinuousClock.now)
        let makeProgress: @Sendable (CleanupCategory, String) -> Void = { category, path in
            // Bound UI work across all concurrent scanners to ten updates per second.
            let shouldReport = lastProgressTime.withLock { last in
                let now = ContinuousClock.now
                guard now - last >= .milliseconds(100) else { return false }
                last = now
                return true
            }
            guard shouldReport, !Task.isCancelled, control?.isCancelled != true else { return }
            let bytes = runningBytes.withLock { $0 }
            let count = runningCount.withLock { $0 }
            let completed = completedCategories.withLock { $0 }
            progressHandler(ScanProgress(
                currentCategory: category,
                currentPath: path,
                scannedBytes: bytes,
                scannedItemsCount: count,
                completedCategoriesCount: completed,
                totalCategoriesCount: totalCategories
            ))
        }

        // Run all scanners concurrently using a TaskGroup
        await withTaskGroup(of: [ScanItem].self) { group in
            group.addTask { await self.cacheScanner.scan(onProgress: { makeProgress(.systemCache, $0) }, control: control) }
            group.addTask { await self.logScanner.scan(onProgress: { makeProgress(.userLogs, $0) }, control: control) }
            group.addTask { await self.trashScanner.scan(onProgress: { makeProgress(.trash, $0) }, control: control) }
            group.addTask { await self.xcodeScanner.scan(onProgress: { makeProgress(.developerXcode, $0) }, control: control) }
            group.addTask { await self.gradleScanner.scan(onProgress: { makeProgress(.developerGradle, $0) }, control: control) }
            group.addTask { await self.nodeScanner.scan(onProgress: { makeProgress(.developerNode, $0) }, control: control) }
            group.addTask { await self.homebrewScanner.scan(onProgress: { makeProgress(.developerHomebrew, $0) }, control: control) }
            group.addTask { await self.dockerScanner.scan(onProgress: { makeProgress(.developerDocker, $0) }, control: control) }

            for await scanItems in group {
                if Task.isCancelled || control?.isCancelled == true {
                    group.cancelAll()
                    break
                }
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
                let completed = completedCategories.withLock {
                    $0 += 1
                    return $0
                }

                allItems.append(contentsOf: newValidItems)

                progressHandler(ScanProgress(
                    scannedBytes: runningBytes.withLock { $0 },
                    scannedItemsCount: runningCount.withLock { $0 },
                    completedCategoriesCount: completed,
                    totalCategoriesCount: totalCategories
                ))
            }
        }

        // Sort items by size descending
        allItems.sort { $0.size > $1.size }

        let duration = Date().timeIntervalSince(startTime)
        let totalBytes = allItems.reduce(0) { $0 + $1.size }

        Logger.scanner.info("Full Scan complete: \(allItems.count) items, \(ByteFormatter.format(totalBytes)), \(String(format: "%.1f", duration))s")

        if !Task.isCancelled && control?.isCancelled != true {
            progressHandler(ScanProgress.completed(
                totalBytes: totalBytes,
                totalItems: allItems.count,
                totalCategories: totalCategories
            ))
        }

        return ScanResult(
            items: allItems,
            duration: duration,
            scannedCategories: Array(Set(allItems.map(\.category)))
        )
    }

    /// Runs a developer-only scan targeting dev tool caches.
    public func performDeveloperScan(
        control: ScanControl? = nil,
        progressHandler: @escaping @Sendable (ScanProgress) -> Void = { _ in }
    ) async -> ScanResult {
        let startTime = Date()
        var allItems: [CleanupItem] = []
        let runningBytes = OSAllocatedUnfairLock(initialState: Int64(0))
        let runningCount = OSAllocatedUnfairLock(initialState: 0)
        let completedCategories = OSAllocatedUnfairLock(initialState: 0)
        let totalCategories = 5

        let lastProgressTime = OSAllocatedUnfairLock(initialState: ContinuousClock.now)
        let makeProgress: @Sendable (CleanupCategory, String) -> Void = { category, path in
            // Bound UI work across all concurrent scanners to ten updates per second.
            let shouldReport = lastProgressTime.withLock { last in
                let now = ContinuousClock.now
                guard now - last >= .milliseconds(100) else { return false }
                last = now
                return true
            }
            guard shouldReport, !Task.isCancelled, control?.isCancelled != true else { return }
            progressHandler(ScanProgress(
                currentCategory: category,
                currentPath: path,
                scannedBytes: runningBytes.withLock { $0 },
                scannedItemsCount: runningCount.withLock { $0 },
                completedCategoriesCount: completedCategories.withLock { $0 },
                totalCategoriesCount: totalCategories
            ))
        }

        await withTaskGroup(of: [ScanItem].self) { group in
            group.addTask { await self.xcodeScanner.scan(onProgress: { makeProgress(.developerXcode, $0) }, control: control) }
            group.addTask { await self.gradleScanner.scan(onProgress: { makeProgress(.developerGradle, $0) }, control: control) }
            group.addTask { await self.nodeScanner.scan(onProgress: { makeProgress(.developerNode, $0) }, control: control) }
            group.addTask { await self.homebrewScanner.scan(onProgress: { makeProgress(.developerHomebrew, $0) }, control: control) }
            group.addTask { await self.dockerScanner.scan(onProgress: { makeProgress(.developerDocker, $0) }, control: control) }

            for await scanItems in group {
                if Task.isCancelled || control?.isCancelled == true {
                    group.cancelAll()
                    break
                }
                var newValidItems: [CleanupItem] = []
                for item in scanItems {
                    if safetyValidator.validate(item.url) == .approved {
                        newValidItems.append(item.toCleanupItem())
                    }
                }

                let addedBytes = newValidItems.reduce(0) { $0 + $1.size }
                let addedCount = newValidItems.count
                runningBytes.withLock { $0 += addedBytes }
                runningCount.withLock { $0 += addedCount }
                let completed = completedCategories.withLock {
                    $0 += 1
                    return $0
                }

                allItems.append(contentsOf: newValidItems)
                progressHandler(ScanProgress(
                    scannedBytes: runningBytes.withLock { $0 },
                    scannedItemsCount: runningCount.withLock { $0 },
                    completedCategoriesCount: completed,
                    totalCategoriesCount: totalCategories
                ))
            }
        }

        allItems.sort { $0.size > $1.size }
        let duration = Date().timeIntervalSince(startTime)

        if !Task.isCancelled && control?.isCancelled != true {
            progressHandler(ScanProgress.completed(
                totalBytes: allItems.reduce(0) { $0 + $1.size },
                totalItems: allItems.count,
                totalCategories: totalCategories
            ))
        }

        return ScanResult(
            items: allItems,
            duration: duration,
            scannedCategories: Array(Set(allItems.map(\.category)))
        )
    }
}
