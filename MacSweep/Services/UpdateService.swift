import Foundation
import Combine
#if canImport(Sparkle)
import Sparkle
#endif

/// Securely checks, downloads, verifies, and installs application updates.
@MainActor
public final class UpdateService: ObservableObject {
#if canImport(Sparkle)
    private let controller: SPUStandardUpdaterController
#endif
    public let isConfigured: Bool

    public init() {
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        let configured = !(publicKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        isConfigured = configured
#if canImport(Sparkle)
        controller = SPUStandardUpdaterController(
            startingUpdater: configured,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
#endif
    }

    public var automaticallyChecksForUpdates: Bool {
        get {
#if canImport(Sparkle)
            controller.updater.automaticallyChecksForUpdates
#else
            UserDefaults.standard.object(forKey: "automaticallyChecksForUpdates") as? Bool ?? true
#endif
        }
        set {
            objectWillChange.send()
#if canImport(Sparkle)
            controller.updater.automaticallyChecksForUpdates = newValue
#else
            UserDefaults.standard.set(newValue, forKey: "automaticallyChecksForUpdates")
#endif
        }
    }

    public var automaticallyDownloadsUpdates: Bool {
        get {
#if canImport(Sparkle)
            controller.updater.automaticallyDownloadsUpdates
#else
            UserDefaults.standard.bool(forKey: "automaticallyDownloadsUpdates")
#endif
        }
        set {
            objectWillChange.send()
#if canImport(Sparkle)
            controller.updater.automaticallyDownloadsUpdates = newValue
#else
            UserDefaults.standard.set(newValue, forKey: "automaticallyDownloadsUpdates")
#endif
        }
    }

    public var canCheckForUpdates: Bool {
#if canImport(Sparkle)
        isConfigured && controller.updater.canCheckForUpdates
#else
        false
#endif
    }

    public func checkForUpdates() {
        guard isConfigured else { return }
#if canImport(Sparkle)
        controller.checkForUpdates(nil)
#endif
    }
}
