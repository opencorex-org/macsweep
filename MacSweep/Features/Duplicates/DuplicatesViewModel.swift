import SwiftUI
import Combine

@MainActor
public final class DuplicatesViewModel: ObservableObject {
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isCleaning: Bool = false
    @Published public var groups: [DuplicateGroup] = []
    @Published public var selectedDirectories: [URL] = [FileManager.default.homeDirectoryForCurrentUser]

    private let service = DuplicateDetectionService()

    public var totalWastedSpace: Int64 {
        groups.reduce(0) { $0 + $1.wastedSpace }
    }

    public var selectedBytesCount: Int64 {
        groups.reduce(0) { groupSum, group in
            let selectedCountInGroup = Int64(group.files.filter(\.isSelected).count)
            return groupSum + (selectedCountInGroup * group.fileSize)
        }
    }

    public var selectedFilesCount: Int {
        groups.reduce(0) { $0 + $1.files.filter(\.isSelected).count }
    }

    public init() {}

    public func scanForDuplicates() async {
        guard !isScanning else { return }
        isScanning = true
        let results = await service.findDuplicates(in: selectedDirectories)
        self.groups = results
        self.isScanning = false
    }

    public func selectAllExceptNewest() {
        for groupIndex in groups.indices {
            let sorted = groups[groupIndex].files.sorted(by: { $0.modificationDate > $1.modificationDate })
            if let newestID = sorted.first?.id {
                for fileIndex in groups[groupIndex].files.indices {
                    groups[groupIndex].files[fileIndex].isSelected = (groups[groupIndex].files[fileIndex].id != newestID)
                }
            }
        }
    }

    public func selectAllExceptOldest() {
        for groupIndex in groups.indices {
            let sorted = groups[groupIndex].files.sorted(by: { $0.modificationDate < $1.modificationDate })
            if let oldestID = sorted.first?.id {
                for fileIndex in groups[groupIndex].files.indices {
                    groups[groupIndex].files[fileIndex].isSelected = (groups[groupIndex].files[fileIndex].id != oldestID)
                }
            }
        }
    }

    public func toggleFileSelection(groupID: UUID, fileID: UUID) {
        if let gIndex = groups.firstIndex(where: { $0.id == groupID }),
           let fIndex = groups[gIndex].files.firstIndex(where: { $0.id == fileID }) {
            groups[gIndex].files[fIndex].isSelected.toggle()
        }
    }

    public func deleteSelectedDuplicates() async {
        guard !isCleaning else { return }
        isCleaning = true

        let fileManager = FileManager.default
        for groupIndex in groups.indices {
            var filesToRemove: [UUID] = []
            for file in groups[groupIndex].files where file.isSelected {
                do {
                    try fileManager.removeItem(at: file.url)
                    filesToRemove.append(file.id)
                } catch {
                    // Log error if needed
                }
            }
            groups[groupIndex].files.removeAll { filesToRemove.contains($0.id) }
        }
        groups.removeAll { $0.files.count <= 1 }
        isCleaning = false
    }
}
