import Foundation
import AppKit
import OSLog
import Combine

/// Centralized permission state manager that tracks Full Disk Access
/// and other permission grants across the application lifecycle.
@MainActor
public final class PermissionManager: ObservableObject {
    @Published public var hasFullDiskAccess: Bool = false

    private var notificationObserver: NSObjectProtocol?

    public init() {
        refreshPermissions()
        observeAppActivation()
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Refreshes all permission states.
    public func refreshPermissions() {
        let refreshedValue = FullDiskAccessManager.shared.hasFullDiskAccess
        if hasFullDiskAccess != refreshedValue {
            hasFullDiskAccess = refreshedValue
        }
        Logger.permissions.info("Permissions refreshed — FDA: \(refreshedValue)")
    }

    /// Opens System Settings to the Full Disk Access pane.
    public func requestFullDiskAccess() {
        FullDiskAccessManager.shared.openSystemSettings()
    }

    /// Observes app activation events to re-check permissions dynamically.
    private func observeAppActivation() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // App activation can arrive while SwiftUI is reconciling a view tree.
            // Defer publication to the next main-run-loop turn.
            DispatchQueue.main.async {
                self?.refreshPermissions()
            }
        }
    }
}
