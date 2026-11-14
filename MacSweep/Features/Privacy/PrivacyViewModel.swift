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

    private let environment: AppEnvironment

    public init(environment: AppEnvironment) { self.environment = environment }

    public func scanPrivacyItems() async {
        guard !isScanning else { return }
        isScanning = true
        if environment.ignoreListStore.categories.contains(.browserPrivacy) {
            items = []
            isScanning = false
            return
        }

        var discovered: [PrivacyItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        // Safari Caches & History
        let safariCache = home.appendingPathComponent("Library/Caches/com.apple.Safari")
        if !environment.ignoreListStore.contains(safariCache), let size = await (try? FileEnumerator.directorySize(safariCache)), size > 0 {
            discovered.append(PrivacyItem(browserName: "Safari", title: "Cache & Web Data", iconName: "safari.fill", path: safariCache, size: size, isSelected: true))
        }

        // Chrome Caches
        let chromeCache = home.appendingPathComponent("Library/Caches/Google/Chrome")
        if !environment.ignoreListStore.contains(chromeCache), let size = await (try? FileEnumerator.directorySize(chromeCache)), size > 0 {
            discovered.append(PrivacyItem(browserName: "Google Chrome", title: "Cache & Cookies", iconName: "globe", path: chromeCache, size: size, isSelected: true))
        }

        // Firefox Caches
        let firefoxCache = home.appendingPathComponent("Library/Caches/org.mozilla.firefox")
        if !environment.ignoreListStore.contains(firefoxCache), let size = await (try? FileEnumerator.directorySize(firefoxCache)), size > 0 {
            discovered.append(PrivacyItem(browserName: "Firefox", title: "Cache", iconName: "globe", path: firefoxCache, size: size, isSelected: true))
        }

        // Arc Caches
        let arcCache = home.appendingPathComponent("Library/Caches/company.thebrowser.Browser")
        if !environment.ignoreListStore.contains(arcCache), let size = await (try? FileEnumerator.directorySize(arcCache)), size > 0 {
            discovered.append(PrivacyItem(browserName: "Arc", title: "Cache", iconName: "globe", path: arcCache, size: size, isSelected: true))
        }

        let extraBrowsers = [
            ("Microsoft Edge", "Microsoft Edge"),
            ("Brave", "BraveSoftware/Brave-Browser")
        ]
        for (name, relativePath) in extraBrowsers {
            let cache = home.appendingPathComponent("Library/Caches/\(relativePath)")
            if !environment.ignoreListStore.contains(cache), let size = await (try? FileEnumerator.directorySize(cache)), size > 0 {
                discovered.append(PrivacyItem(browserName: name, title: "Cache", iconName: "globe", path: cache, size: size, isSelected: true))
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

    public func cleanPrivacyItems() async {
        guard !isCleaning else { return }
        isCleaning = true

        let selected = items.filter(\.isSelected)
        let cleanupItems = selected.map {
            CleanupItem(url: $0.path, name: $0.browserName, size: $0.size, category: .browserPrivacy, risk: .caution, isDirectory: true, modificationDate: Date(), isSelected: true)
        }
        let result = await environment.cleanEngine.clean(items: cleanupItems)
        environment.activityLogStore.recordCleanup(result, title: "Browser cache cleanup completed")
        let failed = Set(result.failures.map(\.url))
        items.removeAll { $0.isSelected && !failed.contains($0.path) }
        isCleaning = false
    }
}
