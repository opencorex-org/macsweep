import Foundation
import OSLog

/// Scans Xcode-related developer caches including DerivedData, Archives, and SPM caches.
public nonisolated struct XcodeScanner: Sendable {
    private var fileManager: FileManager { .default }

    private var targetPaths: [(url: URL, label: String, risk: CleanupRisk)] {
        let home = fileManager.homeDirectoryForCurrentUser
        let dev = home.appendingPathComponent("Library/Developer/Xcode")
        return [
            (dev.appendingPathComponent("DerivedData"), "DerivedData", .safe),
            (dev.appendingPathComponent("Archives"), "Archives", .caution),
            (dev.appendingPathComponent("iOS DeviceSupport"), "iOS Device Support", .caution),
            (dev.appendingPathComponent("Products"), "Build Products", .safe),
            (home.appendingPathComponent("Library/Developer/CoreSimulator/Caches"), "Simulator Caches", .safe),
            (home.appendingPathComponent("Library/Caches/org.swift.swiftpm"), "Swift Package Manager Cache", .safe),
            (home.appendingPathComponent("Library/Caches/CocoaPods"), "CocoaPods Cache", .safe)
        ]
    }

    @concurrent
    public func scan(onProgress: (@Sendable (String) -> Void)? = nil, control: ScanControl? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label, risk) in targetPaths {
            guard await control?.waitUntilRunnable() ?? !Task.isCancelled else { return items }
            guard fileManager.fileExists(atPath: path.path) else { continue }
            onProgress?(path.path)
            Logger.scanner.debug("Scanning Xcode path: \(label)")

            let size = await FileEnumerator.directorySize(path, onProgress: onProgress, control: control)
            guard size > 0 else { continue }

            let modDate = (try? path.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast

            items.append(ScanItem(
                url: path,
                size: size,
                category: .developerXcode,
                risk: risk,
                isDirectory: true,
                modificationDate: modDate
            ))
        }

        Logger.scanner.info("Xcode scan complete: \(items.count) items")
        return items
    }
}
