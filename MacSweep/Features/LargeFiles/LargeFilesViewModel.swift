import SwiftUI
import Combine

@MainActor
public final class LargeFilesViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public var files: [LargeFile] = []
    @Published public var thresholdInMB: Int64 = 100

    private let service: LargeFileService

    public var selectedBytes: Int64 {
        files.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    public var selectedCount: Int {
        files.filter(\.isSelected).count
    }

    public init(service: LargeFileService = LargeFileService()) {
        self.service = service
    }

    public func scanLargeFiles() async {
        guard !isScanning else { return }
        isScanning = true
        let thresholdBytes = thresholdInMB * 1024 * 1024
        let results = await service.findLargeFiles(threshold: thresholdBytes)
        self.files = results
        self.isScanning = false
    }

    public func toggleFileSelection(_ file: LargeFile) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index].isSelected.toggle()
        }
    }

    public func removeSelectedFiles() async {
        guard !isCleaning else { return }
        isCleaning = true

        let fileManager = FileManager.default
        var idsToRemove: [UUID] = []
        for file in files where file.isSelected {
            do {
                try fileManager.removeItem(at: file.url)
                idsToRemove.append(file.id)
            } catch {
                // Ignore or log error
            }
        }
        files.removeAll { idsToRemove.contains($0.id) }
        isCleaning = false
    }
}
