import SwiftUI

public struct SmartScanView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel: SmartScanViewModel
    @State private var showConfirmDialog = false

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: SmartScanViewModel(environment: environment))
    }

    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.isScanning {
                ScanProgressView(progress: viewModel.currentProgress)
            } else if let cleanResult = viewModel.lastCleanResult {
                ScanSummaryView(result: cleanResult)
                    .overlay(
                        VStack {
                            Spacer()
                            PrimaryButton(title: "Scan Again", iconName: "arrow.clockwise") {
                                Task { await viewModel.startScan() }
                            }
                            .padding(.bottom, 24)
                        }
                    )
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "Smart Scan",
                    subtitle: "Scan your Mac to identify safe-to-remove cache files, system logs, user trash, and outdated developer artifacts.",
                    iconName: "sparkles",
                    buttonTitle: "Start Smart Scan",
                    buttonAction: {
                        Task { await viewModel.startScan() }
                    }
                )
            } else {
                // Results List
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan Results")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.msLabel)
                            Text("\(viewModel.selectedCount) items selected (\(ByteFormatter.format(viewModel.selectedBytes)))")
                                .font(.system(size: 12))
                                .foregroundColor(.msSecondaryLabel)
                        }

                        Spacer()

                        PrimaryButton(
                            title: "Clean \(ByteFormatter.format(viewModel.selectedBytes))",
                            iconName: "trash.fill",
                            isLoading: viewModel.isCleaning
                        ) {
                            showConfirmDialog = true
                        }
                        .disabled(viewModel.selectedCount == 0)
                    }
                    .padding(16)
                    .background(Color.msSecondaryBackground)

                    Divider()

                    // Content List
                    List {
                        let grouped = Dictionary(grouping: viewModel.items, by: \.category)
                        ForEach(Array(grouped.keys), id: \.self) { category in
                            Section(header: ScanCategoryHeader(category: category, items: grouped[category] ?? [], viewModel: viewModel)) {
                                ForEach(grouped[category] ?? []) { item in
                                    ScanResultRow(item: item) {
                                        viewModel.toggleItemSelection(item)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmationDialog(
                title: "Clean Selected Items?",
                message: "Are you sure you want to permanently delete \(viewModel.selectedCount) items (\(ByteFormatter.format(viewModel.selectedBytes)))?",
                confirmTitle: "Clean Now",
                isDestructive: true,
                onConfirm: {
                    showConfirmDialog = false
                    Task { await viewModel.performCleanup() }
                },
                onCancel: {
                    showConfirmDialog = false
                }
            )
        }
    }
}

private struct ScanCategoryHeader: View {
    let category: CleanupCategory
    let items: [CleanupItem]
    @ObservedObject var viewModel: SmartScanViewModel

    var isAllSelected: Bool {
        items.allSatisfy(\.isSelected)
    }

    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isAllSelected },
                set: { viewModel.toggleCategorySelection(category, isSelected: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            Image(systemName: category.iconName)
                .foregroundColor(category.tintColor)

            Text(category.displayName)
                .font(.system(size: 13, weight: .bold))

            Spacer()

            Text(ByteFormatter.format(items.reduce(0) { $0 + $1.size }))
                .font(.system(size: 12))
                .foregroundColor(.msSecondaryLabel)
        }
    }
}
