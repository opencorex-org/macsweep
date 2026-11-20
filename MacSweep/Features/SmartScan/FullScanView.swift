import SwiftUI

public struct FullScanView: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @StateObject private var viewModel: FullScanViewModel
    @State private var showConfirmation = false

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: FullScanViewModel(environment: environment))
    }

    public var body: some View {
        Group {
            if viewModel.isScanning {
                ScanProgressView(
                    progress: viewModel.currentProgress,
                    isPaused: viewModel.isPaused,
                    onPauseResume: viewModel.togglePause,
                    onStop: viewModel.stopScan
                )
            } else if viewModel.isCleaning {
                CleaningProgressView(
                    progress: viewModel.cleanProgress,
                    title: "Cleaning Full Scan Items",
                    subtitle: "Permanently removing selected system and application caches…"
                )
            } else if let result = viewModel.lastCleanResult {
                ScanSummaryView(result: result, onScanAgain: startScan)
            } else if viewModel.scanResult == nil {
                EmptyStateView(
                    title: "Full Scan",
                    subtitle: "Review system, developer, and custom-rule findings—including caution items—in one comprehensive scan.",
                    iconName: "magnifyingglass.circle.fill",
                    buttonTitle: "Start Full Scan",
                    buttonAction: startScan
                )
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "Full Scan Complete",
                    subtitle: "No supported cleanup items were found.",
                    iconName: "checkmark.shield.fill",
                    buttonTitle: "Scan Again",
                    buttonAction: startScan
                )
            } else {
                results
            }
        }
        .task {
            if coordinator.consumeFullScanRequest() {
                await viewModel.startScan()
            }
        }
        .sheet(isPresented: $showConfirmation) {
            ConfirmationDialog(
                title: "Approve Full Scan Cleanup?",
                message: "Permanently delete \(viewModel.selectedCount) selected items (\(ByteFormatter.format(viewModel.selectedBytes)))? This cannot be undone. Caution items are not selected by default.",
                confirmTitle: "Permanently Delete",
                isDestructive: true,
                onConfirm: {
                    showConfirmation = false
                    Task { await viewModel.cleanSelected() }
                },
                onCancel: { showConfirmation = false }
            )
        }
    }

    private var results: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Full Scan Results")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.msLabel)
                        Text("\(viewModel.items.count) items found across system and developer categories")
                            .font(.system(size: 12))
                            .foregroundColor(.msSecondaryLabel)
                    }
                    Spacer()
                    Button(action: startScan) {
                        Label("Scan Again", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    PrimaryButton(
                        title: "Clean \(ByteFormatter.format(viewModel.selectedBytes))",
                        iconName: "trash",
                        isLoading: viewModel.isCleaning
                    ) {
                        showConfirmation = true
                    }
                    .disabled(viewModel.selectedCount == 0 || viewModel.isCleaning)
                }

                HStack(spacing: 14) {
                    Button("Recommended Only") { viewModel.selectSafeOnly() }
                    Button("Select All") { viewModel.selectAll() }
                    Button("Deselect All") { viewModel.deselectAll() }
                    Spacer()
                    Text("\(viewModel.selectedCount) selected • \(ByteFormatter.format(viewModel.selectedBytes)) of \(ByteFormatter.format(viewModel.totalBytes))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.msSecondaryLabel)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11, weight: .medium))
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            List {
                ForEach(categories, id: \.self) { category in
                    let categoryItems = items(in: category)
                    Section {
                        ForEach(categoryItems) { item in
                            ScanResultRow(item: item) { viewModel.toggle(item) }
                        }
                    } header: {
                        categoryHeader(category, items: categoryItems)
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private var categories: [CleanupCategory] {
        CleanupCategory.allCases.filter { category in
            viewModel.items.contains { $0.category == category }
        }
    }

    private func items(in category: CleanupCategory) -> [CleanupItem] {
        viewModel.items.filter { $0.category == category }
    }

    private func categoryHeader(_ category: CleanupCategory, items: [CleanupItem]) -> some View {
        let allSelected = items.allSatisfy(\.isSelected)
        return HStack {
            Toggle("", isOn: Binding(
                get: { allSelected },
                set: { viewModel.setSelection(for: category, isSelected: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)
            Image(systemName: category.iconName).foregroundColor(category.tintColor)
            Text(LocalizedStringKey(category.displayName)).font(.system(size: 13, weight: .bold))
            Spacer()
            Text(ByteFormatter.format(items.reduce(0) { $0 + $1.size }))
                .font(.system(size: 11))
                .foregroundColor(.msSecondaryLabel)
        }
    }

    private func startScan() {
        Task { await viewModel.startScan() }
    }
}
