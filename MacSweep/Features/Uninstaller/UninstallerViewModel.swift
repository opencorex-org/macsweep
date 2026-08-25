import SwiftUI
import Combine

@MainActor
public final class UninstallerViewModel: ObservableObject {
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isUninstalling: Bool = false
    @Published public var applications: [ApplicationInfo] = []
    @Published public var selectedApp: ApplicationInfo?
    @Published public var searchText: String = ""

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
        guard !isLoading else { return }
        isLoading = true
        let apps = await service.discoverApplications()
        self.applications = apps
        self.isLoading = false
    }

    public func uninstallApplication(_ app: ApplicationInfo) async {
        guard !isUninstalling else { return }
        isUninstalling = true

        let fm = FileManager.default
        // Remove app bundle
        try? fm.removeItem(at: app.bundleURL)

        // Remove leftover files
        for leftover in app.leftovers {
            try? fm.removeItem(at: leftover.url)
        }

        applications.removeAll { $0.id == app.id }
        if selectedApp?.id == app.id {
            selectedApp = nil
        }
        isUninstalling = false
    }
}
