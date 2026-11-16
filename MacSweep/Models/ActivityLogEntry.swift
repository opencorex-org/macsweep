import Foundation

public struct ActivityLogEntry: Identifiable, Codable, Sendable {
    public enum Kind: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
        case scan
        case cleanup
        case uninstall
        case transfer

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .scan: "Scans"
            case .cleanup: "Cleanups"
            case .uninstall: "Uninstalls"
            case .transfer: "App Moves"
            }
        }

        public var icon: String {
            switch self {
            case .scan: "magnifyingglass"
            case .cleanup: "sparkles"
            case .uninstall: "trash.fill"
            case .transfer: "externaldrive.fill"
            }
        }
    }

    public enum Status: String, Codable, Sendable {
        case success
        case warning
        case failure
    }

    public let id: UUID
    public let date: Date
    public let kind: Kind
    public let status: Status
    public let title: String
    public let detail: String
    public let itemCount: Int
    public let byteCount: Int64
    public let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        kind: Kind,
        status: Status,
        title: String,
        detail: String,
        itemCount: Int = 0,
        byteCount: Int64 = 0,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.status = status
        self.title = title
        self.detail = detail
        self.itemCount = itemCount
        self.byteCount = byteCount
        self.duration = duration
    }
}
