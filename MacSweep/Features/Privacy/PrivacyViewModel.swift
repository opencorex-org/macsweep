import SwiftUI
import Combine

public struct PrivacyItem: Identifiable, Sendable {
    public let id = UUID()
    public let browserName: String
    public let title: String
    public let iconName: String
    public let path: URL
    public let size: Int64
    public var isSelected: Bool
}

@MainActor
public final class PrivacyViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public var items: [PrivacyItem] = []

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

        // Safari Caches & History
        let safariCache = home.appendingPathComponent("Library/Caches/com.apple.Safari")
        if let size = await (try? FileEnumerator.directorySize(safariCache)), size > 0 {
            discovered.append(PrivacyItem(browserName: "Safari", title: "Cache & Web Data", iconName: "safari.fill", path: safariCache, size: size, isSelected: true))
        }

        // Chrome Caches
        let chromeCache = home.appendingPathComponent("Library/Caches/Google/Chrome")
        if let size = await (try? FileEnumerator.directorySize(chromeCache)), size > 0 {
            discovered.append(PrivacyItem(browserName: "Google Chrome", title: "Cache & Cookies", iconName: "globe", path: chromeCache, size: size, isSelected: true))
        }

        // Firefox Caches
        let firefoxCache = home.appendingPathComponent("Library/Caches/Firefox")
        if let size = await (try? FileEnumerator.directorySize(firefoxCache)), size > 0 {
            discovered.append(PrivacyItem(browserName: "Firefox", title: "Cache", iconName: "globe", path: firefoxCache, size: size, isSelected: true))
        }

        // Arc Caches
        let arcCache = home.appendingPathComponent("Library/Caches/company.thebrowser.Browser")
        if let size = await (try? FileEnumerator.directorySize(arcCache)), size > 0 {
            discovered.append(PrivacyItem(browserName: "Arc", title: "Cache", iconName: "globe", path: arcCache, size: size, isSelected: true))
        }

        self.items = discovered
        self.isScanning = false
    }

    public func toggleItemSelection(_ item: PrivacyItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
    }

    public func cleanPrivacyItems() async {
        guard !isCleaning else { return }
        isCleaning = true

        let fm = FileManager.default
        var idsToRemove: [UUID] = []
        for item in items where item.isSelected {
            do {
                try fm.removeItem(at: item.path)
                idsToRemove.append(item.id)
            } catch {
                // Ignore
            }
        }
        items.removeAll { idsToRemove.contains($0.id) }
        isCleaning = false
    }
}
