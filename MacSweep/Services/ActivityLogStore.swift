import Foundation
import Combine

@MainActor
public final class ActivityLogStore: ObservableObject {
    @Published public private(set) var entries: [ActivityLogEntry]

    private let defaults: UserDefaults
    private static let storageKey = "MacSweepActivityLog"
    private static let maximumEntryCount = 500

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let savedEntries = try? JSONDecoder().decode([ActivityLogEntry].self, from: data) {
            self.entries = savedEntries.sorted { $0.date > $1.date }
        } else {
            self.entries = []
        }
    }

    public func record(_ entry: ActivityLogEntry) {
        entries.insert(entry, at: 0)
        if entries.count > Self.maximumEntryCount {
            entries.removeLast(entries.count - Self.maximumEntryCount)
        }
        save()
    }

    public func recordScan(_ result: ScanResult, title: String) {
        record(ActivityLogEntry(
            kind: .scan,
            status: .success,
            title: title,
            detail: result.items.isEmpty ? "No cleanable files found" : "Found \(result.items.count) cleanable items",
            itemCount: result.items.count,
            byteCount: result.totalBytes,
            duration: result.duration
        ))
    }

    public func recordCleanup(_ result: CleanResult, title: String) {
        record(ActivityLogEntry(
            kind: .cleanup,
            status: status(success: result.successCount, failures: result.failureCount),
            title: title,
            detail: result.failureCount == 0
                ? "Cleanup completed successfully"
                : "Completed with \(result.failureCount) failed item\(result.failureCount == 1 ? "" : "s")",
            itemCount: result.totalItemsProcessed,
            byteCount: result.totalBytesReclaimed,
            duration: result.duration
        ))
    }

    public func recordUninstall(_ result: ApplicationUninstallResult) {
        record(ActivityLogEntry(
            kind: .uninstall,
            status: result.isFullSuccess ? .success : (result.appBundleMovedToTrash ? .warning : .failure),
            title: "Uninstalled \(result.applicationName)",
            detail: result.isFullSuccess
                ? "Application and associated files moved to Trash"
                : "\(result.failures.count) item\(result.failures.count == 1 ? "" : "s") could not be removed",
            itemCount: result.movedItemsCount,
            byteCount: result.movedBytes,
            duration: result.duration
        ))
    }

    public func recordTransfer(_ result: AppFolderMoveResult, isRestore: Bool) {
        record(ActivityLogEntry(
            kind: .transfer,
            status: result.success ? .success : .failure,
            title: "\(isRestore ? "Restored" : "Moved") \(result.folder.appName)",
            detail: result.success
                ? (isRestore ? "Restored to internal storage" : "Moved to \(result.destination.deletingLastPathComponent().lastPathComponent)")
                : (result.errorMessage ?? "The operation could not be completed"),
            itemCount: result.componentsMovedCount,
            byteCount: result.bytesTransferred,
            duration: result.duration
        ))
    }

    public func delete(_ entry: ActivityLogEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    public func clear() {
        entries.removeAll()
        defaults.removeObject(forKey: Self.storageKey)
    }

    public func csvReport() -> String {
        let header = "Date,Type,Status,Title,Detail,Items,Bytes,Duration Seconds"
        let rows = entries.map { entry in
            [
                entry.date.ISO8601Format(), entry.kind.title, entry.status.rawValue,
                entry.title, entry.detail, String(entry.itemCount), String(entry.byteCount), String(format: "%.2f", entry.duration)
            ].map(csvField).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func status(success: Int, failures: Int) -> ActivityLogEntry.Status {
        if failures == 0 { return .success }
        return success > 0 ? .warning : .failure
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
