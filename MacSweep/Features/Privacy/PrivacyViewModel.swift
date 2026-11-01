import AppKit
import SwiftUI
import Combine

public struct PrivacyItem: Identifiable, Sendable {
    public let id = UUID()
    public let browserName: String
    public let title: String
    public let iconName: String
    public let path: URL
    public let size: Int64
    public let bundleIdentifier: String?
    public var isSelected: Bool
}

@MainActor
public final class PrivacyViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public var items: [PrivacyItem] = []
    @Published public private(set) var statusMessage: String?

    public var selectedBytes: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    public var selectedCount: Int {
        items.filter(\.isSelected).count
    }

    public init() {}

    public func scanPrivacyItems() async {
        guard !isScanning else { return }
        isScanning = true

        var discovered: [PrivacyItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        let definitions: [(String, String, String, [(String, String)])] = [
            ("Safari", "com.apple.Safari", "safari.fill", [("Cache", "Library/Caches/com.apple.Safari"), ("History", "Library/Safari/History.db"), ("Cookies", "Library/Cookies/Cookies.binarycookies")]),
            ("Google Chrome", "com.google.Chrome", "globe", [("Cache", "Library/Caches/Google/Chrome"), ("Cookies", "Library/Application Support/Google/Chrome/Default/Cookies"), ("History", "Library/Application Support/Google/Chrome/Default/History")]),
            ("Firefox", "org.mozilla.firefox", "globe", [("Cache", "Library/Caches/Firefox")]),
            ("Arc", "company.thebrowser.Browser", "globe", [("Cache", "Library/Caches/company.thebrowser.Browser"), ("Cookies", "Library/Application Support/Arc/User Data/Default/Cookies"), ("History", "Library/Application Support/Arc/User Data/Default/History")]),
            ("Microsoft Edge", "com.microsoft.edgemac", "globe", [("Cache", "Library/Caches/Microsoft Edge"), ("Cookies", "Library/Application Support/Microsoft Edge/Default/Cookies"), ("History", "Library/Application Support/Microsoft Edge/Default/History")]),
            ("Brave", "com.brave.Browser", "globe", [("Cache", "Library/Caches/BraveSoftware/Brave-Browser"), ("Cookies", "Library/Application Support/BraveSoftware/Brave-Browser/Default/Cookies"), ("History", "Library/Application Support/BraveSoftware/Brave-Browser/Default/History")]),
            ("Opera", "com.operasoftware.Opera", "globe", [("Cache", "Library/Caches/com.operasoftware.Opera"), ("Cookies", "Library/Application Support/com.operasoftware.Opera/Cookies"), ("History", "Library/Application Support/com.operasoftware.Opera/History")]),
            ("Vivaldi", "com.vivaldi.Vivaldi", "globe", [("Cache", "Library/Caches/Vivaldi"), ("Cookies", "Library/Application Support/Vivaldi/Default/Cookies"), ("History", "Library/Application Support/Vivaldi/Default/History")])
        ]

        for (browser, bundleID, icon, targets) in definitions {
            for (title, relativePath) in targets {
                let url = home.appendingPathComponent(relativePath)
                guard FileManager.default.fileExists(atPath: url.path) else { continue }
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey])
                let size = values?.isDirectory == true
                    ? await FileEnumerator.directorySize(url)
                    : Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
                guard size > 0 else { continue }
                discovered.append(PrivacyItem(browserName: browser, title: title, iconName: icon, path: url, size: size, bundleIdentifier: bundleID, isSelected: title == "Cache"))
            }
        }

        self.items = discovered
        self.isScanning = false
    }

    public func toggleItemSelection(_ item: PrivacyItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
    }

    public func cleanPrivacyItems(history: CleanupHistoryService? = nil, notifications: NotificationService? = nil) async {
        guard !isCleaning else { return }
        isCleaning = true

        let fm = FileManager.default
        let started = Date()
        var idsToRemove: [UUID] = []
        var reclaimed: Int64 = 0
        var blocked = Set<String>()
        for item in items where item.isSelected {
            if let bundleID = item.bundleIdentifier,
               !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty {
                blocked.insert(item.browserName)
                continue
            }
            do {
                try fm.removeItem(at: item.path)
                idsToRemove.append(item.id)
                reclaimed += item.size
            } catch {
                // Ignore
            }
        }
        items.removeAll { idsToRemove.contains($0.id) }
        statusMessage = blocked.isEmpty
            ? "Privacy cleanup finished."
            : "Close \(blocked.sorted().joined(separator: ", ")) before cleaning its active profile."
        let result = CleanResult(totalItemsProcessed: idsToRemove.count + blocked.count, successCount: idsToRemove.count, failureCount: blocked.count, totalBytesReclaimed: reclaimed, duration: Date().timeIntervalSince(started))
        history?.record(source: "Privacy Cleaner", result: result)
        notifications?.send(title: "Privacy cleanup finished", body: "Removed \(idsToRemove.count) browser data items using \(ByteFormatter.format(reclaimed)).")
        isCleaning = false
    }
}
