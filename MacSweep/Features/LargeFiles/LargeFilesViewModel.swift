import SwiftUI
import Combine
import AppKit

@MainActor
public final class LargeFilesViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public private(set) var progress: LargeFileScanProgress?
    @Published public private(set) var scanResult: LargeFileScanResult?
    @Published public var files: [LargeFile] = []
    @Published public var thresholdInMB: Int64 {
        didSet {
            UserDefaults.standard.set(Int(thresholdInMB), forKey: "largeFileThresholdMB")
        }
    }
    @Published public private(set) var lastActionMessage: String?
    @Published public private(set) var managementFailures: [String] = []

    private let service: LargeFileService

    public var selectedBytes: Int64 {
        files.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    public var selectedCount: Int {
        files.filter(\.isSelected).count
    }

    public var totalBytes: Int64 {
        files.reduce(0) { $0 + $1.size }
    }

    public init(service: LargeFileService = LargeFileService()) {
        self.service = service
        let storedThreshold = UserDefaults.standard.object(forKey: "largeFileThresholdMB") as? NSNumber
        self.thresholdInMB = storedThreshold?.int64Value ?? 100
    }

    public func scanLargeFiles() async {
        guard !isScanning else { return }
        isScanning = true
        files = []
        scanResult = nil
        lastActionMessage = nil
        managementFailures = []

        let rootsCount = FileAccessManager.shared.scannableRoots.count
        progress = LargeFileScanProgress(
            currentPath: "Preparing scan…",
            scannedFilesCount: 0,
            foundFilesCount: 0,
            foundBytes: 0,
            completedRootsCount: 0,
            totalRootsCount: rootsCount
        )

        // The picker is labelled in decimal MB, so use decimal bytes as well.
        let thresholdBytes = thresholdInMB * 1_000_000
        let result = await service.findLargeFiles(threshold: thresholdBytes) { [weak self] progress in
            Task { @MainActor in
                self?.progress = progress
            }
        }
        self.scanResult = result
        self.files = result.files
        self.isScanning = false
    }

    public func selectAll() {
        for index in files.indices {
            files[index].isSelected = true
        }
    }

    public func deselectAll() {
        for index in files.indices {
            files[index].isSelected = false
        }
    }

    public func toggleFileSelection(_ file: LargeFile) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index].isSelected.toggle()
        }
    }

    public func removeSelectedFiles() async {
        guard !isCleaning, selectedCount > 0 else { return }
        isCleaning = true

        var idsToRemove: [UUID] = []
        var failures: [String] = []
        for file in files where file.isSelected {
            do {
                _ = try TrashService.moveToTrash(file.url)
                idsToRemove.append(file.id)
            } catch {
                failures.append("\(file.name): \(error.localizedDescription)")
            }
        }
        files.removeAll { idsToRemove.contains($0.id) }
        managementFailures = failures
        lastActionMessage = idsToRemove.isEmpty
            ? "No files were moved to Trash."
            : "Moved \(idsToRemove.count) file\(idsToRemove.count == 1 ? "" : "s") to Trash."
        isCleaning = false
    }

    public func revealInFinder(_ file: LargeFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    public func openFile(_ file: LargeFile) {
        NSWorkspace.shared.open(file.url)
    }
}
