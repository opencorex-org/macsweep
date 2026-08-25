import SwiftUI

public struct DeveloperCleanerView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel: DeveloperCleanerViewModel
    @State private var showConfirmDialog = false

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: DeveloperCleanerViewModel(environment: environment))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Developer Cleaner")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)
                    Text("Clean Xcode DerivedData, Node caches, Gradle builds, Homebrew & Docker data")
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                PrimaryButton(
                    title: viewModel.items.isEmpty ? "Scan Developer Caches" : "Clean Selected (\(ByteFormatter.format(viewModel.selectedBytes)))",
                    iconName: viewModel.items.isEmpty ? "hammer.fill" : "trash.fill",
                    isLoading: viewModel.isScanning || viewModel.isCleaning
                ) {
                    if viewModel.items.isEmpty {
                        Task { await viewModel.scanDeveloperCaches() }
                    } else {
                        showConfirmDialog = true
                    }
                }
                .disabled(!viewModel.items.isEmpty && viewModel.selectedCount == 0)
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if viewModel.isScanning {
                LoadingView(title: "Scanning Developer Tools...", subtitle: "Inspecting DerivedData, node_modules, and build caches")
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "No Developer Caches Scanned",
                    subtitle: "Reclaim gigabytes of space trapped in Xcode DerivedData, Gradle build caches, npm/yarn node modules, and Homebrew bottles.",
                    iconName: "hammer.fill",
                    buttonTitle: "Scan Developer Caches",
                    buttonAction: {
                        Task { await viewModel.scanDeveloperCaches() }
                    }
                )
            } else {
                VStack(spacing: 0) {
                    // Quick Cards Summary
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            let grouped = Dictionary(grouping: viewModel.items, by: \.category)
                            ForEach(Array(grouped.keys), id: \.self) { category in
                                let catItems = grouped[category] ?? []
                                DeveloperCacheCard(
                                    title: category.displayName,
                                    subtitle: category.subtitle,
                                    iconName: category.iconName,
                                    tintColor: category.tintColor,
                                    size: catItems.reduce(0) { $0 + $1.size },
                                    count: catItems.count
                                )
                                .frame(width: 220)
                            }
                        }
                        .padding(16)
                    }

                    Divider()

                    // Items List
                    List {
                        ForEach(viewModel.items) { item in
                            DeveloperToolRow(item: item) {
                                viewModel.toggleItemSelection(item)
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmationDialog(
                title: "Clean Developer Caches?",
                message: "Are you sure you want to clean \(viewModel.selectedCount) developer items (\(ByteFormatter.format(viewModel.selectedBytes)))?",
                confirmTitle: "Clean Caches",
                isDestructive: true,
                onConfirm: {
                    showConfirmDialog = false
                    Task { await viewModel.cleanSelectedCaches() }
                },
                onCancel: {
                    showConfirmDialog = false
                }
            )
        }
    }
}
