import SwiftUI

public struct StorageAnalyzerView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = StorageAnalyzerViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Storage Analyzer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)
                    Text("Visual disk space breakdown")
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                SecondaryButton(title: "Analyze Home", iconName: "house.fill") {
                    Task { await viewModel.analyzeDirectory(FileManager.default.homeDirectoryForCurrentUser) }
                }

                PrimaryButton(title: "Analyze Directory", iconName: "folder.badge.plus") {
                    selectFolder()
                }
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if viewModel.isAnalyzing {
                LoadingView(title: "Analyzing Disk Space...", subtitle: "Traversing directory hierarchy")
            } else if let rootNode = viewModel.rootNode {
                VStack(spacing: 12) {
                    StorageChart(node: rootNode)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    StorageTreeView(node: rootNode, selectedNode: $viewModel.selectedNode)
                }
            } else {
                EmptyStateView(
                    title: "Analyze Storage",
                    subtitle: "Select a directory to inspect folder sizes and visualize large files.",
                    iconName: "chart.pie.fill",
                    buttonTitle: "Start Analysis",
                    buttonAction: {
                        Task { await viewModel.analyzeDirectory() }
                    }
                )
            }
        }
        .onAppear {
            if viewModel.rootNode == nil {
                Task { await viewModel.analyzeDirectory() }
            }
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            Task { await viewModel.analyzeDirectory(url) }
        }
    }
}
