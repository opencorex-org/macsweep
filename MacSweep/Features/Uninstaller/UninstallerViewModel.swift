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
    private let activityLogStore: ActivityLogStore

    public var filteredApplications: [ApplicationInfo] {
        if searchText.isEmpty {
            return applications
        }
        return applications.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleURL.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    public init(service: ApplicationService = ApplicationService(), activityLogStore: ActivityLogStore) {
        self.service = service
        self.activityLogStore = activityLogStore
    }

    public func loadApplications() async {
        guard !isLoading, !isUninstalling else { return }
        isLoading = true
        uninstallResult = nil
        let apps = await service.discoverApplications()
        self.applications = apps
        if let selectedPath = selectedApp?.bundleURL.standardizedFileURL.path {
            selectedApp = apps.first { $0.bundleURL.standardizedFileURL.path == selectedPath }
        }
        self.isLoading = false
    }

    public func addApplication(at url: URL) async {
        guard !isLoading, !isUninstalling else { return }
        isLoading = true
        defer { isLoading = false }
        guard let app = await service.inspectApplication(at: url) else { return }
        applications.removeAll { $0.bundleURL.standardizedFileURL.path == app.bundleURL.standardizedFileURL.path }
        applications.append(app)
        applications.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        selectedApp = app
    }

    public func uninstallApplication(_ app: ApplicationInfo) async {
        guard !isUninstalling else { return }
        isUninstalling = true
        uninstallResult = nil
        uninstallingApp = app
        let startedAt = Date()

        let result = await service.uninstall(app) { [weak self] progress in
            Task { @MainActor in
                self?.uninstallProgress = progress
            }
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
        activityLogStore.recordUninstall(result)
        isUninstalling = false
    }

    public func dismissUninstallResult() {
        uninstallResult = nil
        uninstallProgress = nil
        uninstallingApp = nil
    }
}
