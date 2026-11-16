import Foundation

public struct MaintenanceInsight: Identifiable, Hashable, Sendable {
    public enum Kind: String, CaseIterable, Hashable, Sendable {
        case recentFile, installer, screenshot, appCache, browserCache, unusedApp, snapshot

        public var title: String {
            switch self {
            case .recentFile: "Recent large file"
            case .installer: "Old installer"
            case .screenshot: "Screenshot"
            case .appCache: "Application cache"
            case .browserCache: "Browser cache"
            case .unusedApp: "Possibly unused app"
            case .snapshot: "Local Time Machine snapshot"
            }
        }
    }

    public let id: String
    public let kind: Kind
    public let name: String
    public let url: URL?
    public let size: Int64
    public let date: Date?
    public let detail: String

    public init(kind: Kind, name: String, url: URL? = nil, size: Int64 = 0, date: Date? = nil, detail: String) {
        self.kind = kind
        self.name = name
        self.url = url
        self.size = size
        self.date = date
        self.detail = detail
        self.id = "\(kind.rawValue):\(url?.path ?? name)"
    }
}
