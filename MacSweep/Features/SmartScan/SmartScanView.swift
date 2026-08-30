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
                ScanSummaryView(result: cleanResult) {
                    Task { await viewModel.startScan() }
                }
            } else if viewModel.scanResult == nil {
                EmptyStateView(
                    title: "Smart Scan",
                    subtitle: "Scan your Mac to identify safe-to-remove cache files, system logs, user trash, and outdated developer artifacts.",
                    iconName: "sparkles",
                    buttonTitle: "Start Smart Scan",
                    buttonAction: {
                        Task { await viewModel.startScan() }
                    }
                )
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "Scan Complete — Your Mac Is Clean",
                    subtitle: "No cleanup items were found. Nothing will be removed without your review and approval.",
                    iconName: "checkmark.shield.fill",
                    buttonTitle: "Scan Again",
                    buttonAction: {
                        Task { await viewModel.startScan() }
                    }
                )
            } else {
                // Results List
                VStack(spacing: 0) {
                    // Header Bar
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text("Review Scan Results")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.msLabel)

                                    Text("\(ByteFormatter.format(viewModel.totalBytes)) Reclaimable")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.12))
                                        .cornerRadius(6)
                                }

                                Text("Choose what MacSweep may clean. No files are removed until you approve.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.msSecondaryLabel)
                            }

                            Spacer()

                            PrimaryButton(
                                title: "Clean \(ByteFormatter.format(viewModel.selectedBytes))",
                                iconName: "sparkles",
                                isLoading: viewModel.isCleaning
                            ) {
                                showConfirmDialog = true
                            }
                            .disabled(viewModel.selectedCount == 0)
                        }

                        // Quick Filter Controls
                        HStack(spacing: 12) {
                            Button("Safe Items Only") {
                                viewModel.selectSafeOnly()
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 11, weight: .medium))

                            Button("Select All") {
                                viewModel.selectAll()
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 11, weight: .medium))

                            Button("Deselect All") {
                                viewModel.deselectAll()
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 11, weight: .medium))

                            Spacer()

                            Text("\(viewModel.selectedCount) of \(viewModel.items.count) selected • \(ByteFormatter.format(viewModel.selectedBytes))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.msSecondaryLabel)
                        }
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
                title: "Approve Optimization & Cleanup?",
                message: "You are approving the permanent removal of \(viewModel.selectedCount) selected items (\(ByteFormatter.format(viewModel.selectedBytes))) to free up disk space on your Mac. System files and SIP integrity remain protected.",
                confirmTitle: "Approve & Clean \(ByteFormatter.format(viewModel.selectedBytes))",
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
