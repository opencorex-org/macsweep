import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppMoverViewModel: ObservableObject {

    // MARK: - State

    public enum ViewState {
        case idle
        case scanning
        case results
        case moving
        case moveDone
        case error(String)
    }

    public enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case applications = "Applications"
        case dataFolders = "Data Folders"

        public var id: String { rawValue }
    }

    @Published public var viewState: ViewState = .idle

    // Streamed during scanning — folders appear one by one as sizes are calculated
    @Published public var folders: [ManagedAppFolder] = []

    // Live scan progress (updated per-item as scanning happens)
    @Published public var scanProgress: FolderScanProgress?

    @Published public var volumes: [ExternalVolume] = []
    @Published public var selectedFolderID: UUID?
    @Published public var selectedVolumeID: UUID?
    @Published public var moveProgress: FolderMoveProgress?
    @Published public var lastMoveResult: AppFolderMoveResult?

    public enum ActiveSheet: Identifiable {
        case move
        case restore
        public var id: Int { hashValue }
    }

    @Published public var activeSheet: ActiveSheet?

    public var confirmingMove: Bool {
        get { activeSheet == .move }
        set { activeSheet = newValue ? .move : nil }
    }

    public var confirmingRestore: Bool {
        get { activeSheet == .restore }
        set { activeSheet = newValue ? .restore : nil }
    }

    // Filtering & Search
    @Published public var selectedFilter: Filter = .all
    @Published public var searchText: String = ""

    // MARK: - Services

    private let moverService: AppFolderMoverService
    private let volumeService: VolumeService
    private let activityLogStore: ActivityLogStore

    // MARK: - Init

    public init(environment: AppEnvironment) {
        self.moverService = environment.appFolderMoverService
        self.volumeService = environment.volumeService
        self.activityLogStore = environment.activityLogStore
    }

    // MARK: - Computed Properties

    public var selectedFolder: ManagedAppFolder? {
        folders.first { $0.id == selectedFolderID }
    }

    public var selectedVolume: ExternalVolume? {
        volumes.first { $0.id == selectedVolumeID }
    }

    public var externalVolumes: [ExternalVolume] {
        volumes.filter { $0.isExternal && !$0.isReadOnly }
    }

    public var totalSavings: Int64 {
        folders.filter { !$0.isSymlink }.reduce(0) { $0 + $1.size }
    }

    public var applicationsCount: Int {
        folders.filter(\.isAppBundle).count
    }

    public var dataFoldersCount: Int {
        folders.filter { !$0.isAppBundle }.count
    }

    public var filteredFolders: [ManagedAppFolder] {
        folders.filter { folder in
            // Filter by category
            switch selectedFilter {
            case .all:
                break
            case .applications:
                guard folder.isAppBundle else { return false }
            case .dataFolders:
                guard !folder.isAppBundle else { return false }
            }

            // Filter by search text
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let nameMatch = folder.appName.lowercased().contains(query)
                let catMatch = folder.category.lowercased().contains(query)
                let descMatch = folder.description.lowercased().contains(query)
                return nameMatch || catMatch || descMatch
            }

            return true
        }
    }

    /// True while the scan is running and at least one item has appeared
    public var hasPartialResults: Bool {
        !folders.isEmpty
    }

    // MARK: - Scan

    public func scan() async {
        viewState = .scanning
        folders = []
        scanProgress = nil

        // Load volumes in parallel with scanning
        async let volumesTask = volumeService.discoverVolumes()

        // Discover apps & folders — callback fires on MainActor after each size is resolved
        let allFolders = await moverService.discoverManagedFolders { [weak self] folder, progress in
            Task { @MainActor in
                guard let self else { return }
                let insertIndex = self.folders.firstIndex { $0.size < folder.size } ?? self.folders.endIndex
                self.folders.insert(folder, at: insertIndex)
                self.scanProgress = progress
            }
        }

        let discoveredVolumes = await volumesTask

        Task { @MainActor in
            self.volumes = discoveredVolumes
            if self.selectedVolumeID == nil, let firstExt = self.externalVolumes.first {
                self.selectedVolumeID = firstExt.id
            }
            self.folders = allFolders
            self.scanProgress = nil
            self.viewState = .results

            if self.selectedFolderID == nil, let first = self.filteredFolders.first {
                self.selectedFolderID = first.id
            }
        }
    }

    // MARK: - Move

    public func moveToExternal() async {
        guard let folder = selectedFolder, let volume = selectedVolume else { return }
        confirmingMove = false
        viewState = .moving
        moveProgress = nil

        let result = await moverService.move(folder: folder, toVolume: volume) { [weak self] progress in
            self?.moveProgress = progress
        }
        lastMoveResult = result
        activityLogStore.recordTransfer(result, isRestore: false)

        // Refresh list after move
        await scan()
        viewState = .moveDone
    }

    // MARK: - Restore

    public func restoreToInternal() async {
        guard let folder = selectedFolder else { return }
        confirmingRestore = false
        viewState = .moving
        moveProgress = nil

        let result = await moverService.restore(folder: folder) { [weak self] progress in
            self?.moveProgress = progress
        }
        lastMoveResult = result
        activityLogStore.recordTransfer(result, isRestore: true)

        await scan()
        viewState = .moveDone
    }

    // MARK: - Reset

    public func resetAfterMove() {
        lastMoveResult = nil
        moveProgress = nil
        viewState = .results
    }
}
