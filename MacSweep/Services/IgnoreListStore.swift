import Foundation
import Combine

@MainActor
public final class IgnoreListStore: ObservableObject {
    @Published public private(set) var paths: [String]
    @Published public private(set) var categories: Set<CleanupCategory>
    private let defaults: UserDefaults
    private static let key = "MacSweepIgnoredPaths"
    private static let categoryKey = "MacSweepIgnoredCategories"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.paths = defaults.stringArray(forKey: Self.key) ?? []
        self.categories = Set((defaults.stringArray(forKey: Self.categoryKey) ?? []).compactMap { CleanupCategory(rawValue: $0) })
    }

    public func contains(_ url: URL) -> Bool {
        let candidate = url.standardizedFileURL.path
        return paths.contains { candidate == $0 || candidate.hasPrefix($0 + "/") }
    }

    public func contains(_ item: CleanupItem) -> Bool {
        categories.contains(item.category) || contains(item.url)
    }

    public func add(_ url: URL) {
        let path = url.standardizedFileURL.path
        guard !paths.contains(path) else { return }
        paths.append(path)
        paths.sort()
        save()
    }

    public func remove(_ path: String) {
        paths.removeAll { $0 == path }
        save()
    }

    public func toggle(_ category: CleanupCategory) {
        if categories.contains(category) { categories.remove(category) } else { categories.insert(category) }
        defaults.set(categories.map(\.rawValue).sorted(), forKey: Self.categoryKey)
    }

    private func save() { defaults.set(paths, forKey: Self.key) }
}
