import Foundation
import OSLog

/// Scans Xcode-related developer caches including DerivedData, Archives, and SPM caches.
public struct XcodeScanner: Sendable {
    private let fileManager = FileManager.default

    private var targetPaths: [(URL, String)] {
        let home = fileManager.homeDirectoryForCurrentUser
        let dev = home.appendingPathComponent("Library/Developer/Xcode")
        return [
            (dev.appendingPathComponent("DerivedData"), "DerivedData"),
            (dev.appendingPathComponent("Archives"), "Archives"),
            (dev.appendingPathComponent("iOS DeviceSupport"), "iOS Device Support"),
            (dev.appendingPathComponent("Products"), "Build Products"),
            (home.appendingPathComponent("Library/Developer/CoreSimulator/Caches"), "Simulator Caches"),
            (home.appendingPathComponent("Library/Caches/org.swift.swiftpm"), "Swift Package Manager Cache"),
            (home.appendingPathComponent("Library/Caches/CocoaPods"), "CocoaPods Cache")
        ]
    }

    public func scan(onProgress: (@Sendable (String) -> Void)? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            onProgress?(path.path)
            Logger.scanner.debug("Scanning Xcode path: \(label)")

            let size = await FileEnumerator.directorySize(path, onProgress: onProgress)
            guard size > 0 else { continue }

            let modDate = (try? path.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast

            items.append(ScanItem(
                url: path,
                size: size,
                category: .developerXcode,
                isDirectory: true,
                modificationDate: modDate
            ))
        }

        Logger.scanner.info("Xcode scan complete: \(items.count) items")
        return items
    }
}
