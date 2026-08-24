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
            (home.appendingPathComponent("Library/Caches/org.swift.swiftpm"), "Swift Package Manager Cache"),
            (home.appendingPathComponent("Library/Caches/CocoaPods"), "CocoaPods Cache"),
            (home.appendingPathComponent("Library/Developer/CoreSimulator/Caches"), "Simulator Caches")
        ]
    }

    public func scan() async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            Logger.scanner.debug("Scanning Xcode path: \(label)")

            let size = await FileEnumerator.directorySize(path)
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
