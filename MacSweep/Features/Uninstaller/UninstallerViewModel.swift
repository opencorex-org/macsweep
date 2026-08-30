import SwiftUI
import Combine

@MainActor
public final class UninstallerViewModel: ObservableObject {
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isUninstalling: Bool = false
    @Published public var applications: [ApplicationInfo] = []
    @Published public var selectedApp: ApplicationInfo?
    @Published public var searchText: String = ""
    @Published public private(set) var uninstallProgress: ApplicationUninstallProgress?
    @Published public private(set) var uninstallResult: ApplicationUninstallResult?
    @Published public private(set) var uninstallingApp: ApplicationInfo?

    private let service: ApplicationService

    public var filteredApplications: [ApplicationInfo] {
        if searchText.isEmpty {
            return applications
        }
        return applications.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    public init(service: ApplicationService = ApplicationService()) {
        self.service = service
    }

    public func loadApplications() async {
        guard !isLoading, !isUninstalling else { return }
        isLoading = true
        uninstallResult = nil
        let apps = await service.discoverApplications()
        self.applications = apps
        if let selectedBundleID = selectedApp?.bundleIdentifier {
            selectedApp = apps.first { $0.bundleIdentifier == selectedBundleID }
        }
        self.isLoading = false
    }

    public func uninstallApplication(_ app: ApplicationInfo) async {
        guard !isUninstalling else { return }
        isUninstalling = true
        uninstallResult = nil
        uninstallingApp = app
        let startedAt = Date()

        let result = await service.uninstall(app) { [weak self] progress in
            self?.uninstallProgress = progress
        }

        let elapsed = Date().timeIntervalSince(startedAt)
        if elapsed < 1 {
            try? await Task.sleep(nanoseconds: UInt64((1 - elapsed) * 1_000_000_000))
        }

        if result.appBundleMovedToTrash {
            applications.removeAll { $0.id == app.id }
            if selectedApp?.id == app.id {
                selectedApp = nil
            }
        }

        uninstallResult = result
        isUninstalling = false
    }

    public func dismissUninstallResult() {
        uninstallResult = nil
        uninstallProgress = nil
        uninstallingApp = nil
    }
}
