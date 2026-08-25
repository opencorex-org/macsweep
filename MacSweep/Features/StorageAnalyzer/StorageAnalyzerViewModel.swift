import SwiftUI
import Combine

@MainActor
public final class StorageAnalyzerViewModel: ObservableObject {
    @Published public private(set) var isAnalyzing: Bool = false
    @Published public private(set) var rootNode: StorageNode?
    @Published public var selectedNode: StorageNode?
    @Published public var currentDirectoryURL: URL

    private let analyzer = StorageAnalyzer()

    public init(initialURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentDirectoryURL = initialURL
    }

    public func analyzeDirectory(_ url: URL? = nil) async {
        let targetURL = url ?? currentDirectoryURL
        self.currentDirectoryURL = targetURL
        self.isAnalyzing = true

        let result = await analyzer.analyze(rootURL: targetURL)
        self.rootNode = result
        self.selectedNode = result
        self.isAnalyzing = false
    }
}
