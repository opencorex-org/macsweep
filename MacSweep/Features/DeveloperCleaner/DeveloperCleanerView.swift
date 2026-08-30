import SwiftUI

public struct DeveloperCleanerView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel: DeveloperCleanerViewModel
    @State private var showConfirmDialog = false

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: DeveloperCleanerViewModel(environment: environment))
    }

    private var headerButtonStartsScan: Bool {
        viewModel.scanResult == nil || viewModel.items.isEmpty || viewModel.lastCleanResult != nil
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
                    title: headerButtonStartsScan ? "Scan Developer Caches" : "Review & Clean \(ByteFormatter.format(viewModel.selectedBytes))",
                    iconName: headerButtonStartsScan ? "hammer.fill" : "trash.fill",
                    isLoading: viewModel.isScanning || viewModel.isCleaning
                ) {
                    if headerButtonStartsScan {
                        Task { await viewModel.scanDeveloperCaches() }
                    } else {
                        showConfirmDialog = true
                    }
                }
                .disabled(!headerButtonStartsScan && viewModel.selectedCount == 0)
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if viewModel.isScanning {
                ScanProgressView(progress: viewModel.currentProgress)
            } else if let cleanResult = viewModel.lastCleanResult {
                ScanSummaryView(result: cleanResult) {
                    Task { await viewModel.scanDeveloperCaches() }
                }
            } else if viewModel.scanResult == nil {
                EmptyStateView(
                    title: "No Developer Caches Scanned",
                    subtitle: "Reclaim gigabytes of space trapped in Xcode DerivedData, Gradle build caches, npm/yarn node modules, and Homebrew bottles.",
                    iconName: "hammer.fill",
                    buttonTitle: "Scan Developer Caches",
                    buttonAction: {
                        Task { await viewModel.scanDeveloperCaches() }
                    }
                )
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "Developer Scan Complete",
                    subtitle: "No developer caches were found. Nothing was removed, and cleanup always requires your approval.",
                    iconName: "checkmark.shield.fill",
                    buttonTitle: "Scan Again",
                    buttonAction: {
                        Task { await viewModel.scanDeveloperCaches() }
                    }
                )
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Review Developer Cache Results")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.msLabel)
                            Text("Choose what MacSweep may clean. No cache is removed until you approve.")
                                .font(.system(size: 11))
                                .foregroundColor(.msSecondaryLabel)
                        }

                        Spacer()

                        Button("Safe Items Only") {
                            viewModel.selectSafeOnly()
                        }
                        .buttonStyle(.borderless)

                        Button("Select All") {
                            viewModel.selectAll()
                        }
                        .buttonStyle(.borderless)

                        Button("Deselect All") {
                            viewModel.deselectAll()
                        }
                        .buttonStyle(.borderless)

                        Text("\(viewModel.selectedCount) selected • \(ByteFormatter.format(viewModel.selectedBytes))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.msSecondaryLabel)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()

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
                title: "Approve Developer Cache Cleanup?",
                message: "You are approving the permanent removal of \(viewModel.selectedCount) selected developer cache items (\(ByteFormatter.format(viewModel.selectedBytes))). Review the selection before continuing; project source files remain protected.",
                confirmTitle: "Approve & Clean \(ByteFormatter.format(viewModel.selectedBytes))",
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
