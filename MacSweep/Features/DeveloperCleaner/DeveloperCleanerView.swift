import SwiftUI

public struct DeveloperCleanerView: View {
    @StateObject private var viewModel: DeveloperCleanerViewModel
    @State private var showConfirmDialog = false

    private let categories: [CleanupCategory] = [
        .developerXcode, .developerNode, .developerGradle, .developerHomebrew, .developerDocker
    ]

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: DeveloperCleanerViewModel(environment: environment))
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
                    title: "Cleaning Developer Artifacts",
                    subtitle: "Reclaiming space from Xcode, build caches, and developer tools…"
                )
            } else if let result = viewModel.lastCleanResult {
                cleanupSummary(result)
            } else if viewModel.scanResult == nil {
                EmptyStateView(
                    title: "Developer Cleaner",
                    subtitle: "Find rebuildable Xcode, Node.js, Gradle, and Homebrew files. You review every item before anything is permanently deleted.",
                    iconName: "hammer.fill",
                    buttonTitle: "Scan Developer Files",
                    buttonAction: startScan
                )
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "No Developer Clutter Found",
                    subtitle: "The scan completed without finding any supported developer caches that are safe to present for cleanup.",
                    iconName: "checkmark.shield.fill",
                    buttonTitle: "Scan Again",
                    buttonAction: startScan
                )
            } else {
                resultsView
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmationDialog(
                title: "Remove Selected Developer Files?",
                message: "Permanently delete \(viewModel.selectedCount) selected items (\(ByteFormatter.format(viewModel.selectedBytes)))? This cannot be undone. Rebuildable caches may be downloaded or generated again when their tools next run.",
                confirmTitle: "Permanently Delete \(ByteFormatter.format(viewModel.selectedBytes))",
                isDestructive: true,
                onConfirm: {
                    showConfirmDialog = false
                    Task { await viewModel.cleanSelectedCaches() }
                },
                onCancel: { showConfirmDialog = false }
            )
        }
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            resultsHeader
            Divider()

            List {
                ForEach(categoriesWithItems, id: \.self) { category in
                    let categoryItems = items(in: category)
                    Section {
                        ForEach(categoryItems) { item in
                            DeveloperToolRow(item: item) {
                                viewModel.toggleItemSelection(item)
                            }
                        }
                    } header: {
                        categoryHeader(category, items: categoryItems)
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private var resultsHeader: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.msAccent.opacity(0.14))
                        .frame(width: 42, height: 42)
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.msAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Review Developer Files")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.msLabel)
                        Text("\(ByteFormatter.format(viewModel.totalBytes)) FOUND")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.msSafe)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.msSafe.opacity(0.12), in: Capsule())
                    }
                    Text("Select only files you are comfortable regenerating. Approved items are permanently deleted.")
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                Button(action: startScan) {
                    Label("Scan Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isCleaning)

                PrimaryButton(
                    title: "Clean \(ByteFormatter.format(viewModel.selectedBytes))",
                    iconName: "trash",
                    isLoading: viewModel.isCleaning
                ) {
                    showConfirmDialog = true
                }
                .disabled(viewModel.selectedCount == 0 || viewModel.isCleaning)
            }

            HStack(spacing: 14) {
                Button("Recommended Only") { viewModel.selectSafeOnly() }
                Button("Select All") { viewModel.selectAll() }
                Button("Deselect All") { viewModel.deselectAll() }
                Spacer()
                Text("\(viewModel.selectedCount) of \(viewModel.items.count) selected • \(ByteFormatter.format(viewModel.selectedBytes))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11, weight: .medium))
        }
        .padding(16)
        .background(Color.msSecondaryBackground)
    }

    private var categoriesWithItems: [CleanupCategory] {
        categories.filter { !items(in: $0).isEmpty }
    }

    private func items(in category: CleanupCategory) -> [CleanupItem] {
        viewModel.items.filter { $0.category == category }
    }

    private func categoryHeader(_ category: CleanupCategory, items: [CleanupItem]) -> some View {
        let allSelected = items.allSatisfy(\.isSelected)
        return HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: { allSelected },
                set: { viewModel.setSelection(for: category, isSelected: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            Image(systemName: category.iconName)
                .foregroundColor(category.tintColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(category.displayName))
                    .font(.system(size: 13, weight: .bold))
                Text(LocalizedStringKey(category.subtitle))
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
            }
            Spacer()
            Text("\(items.count) items • \(ByteFormatter.format(items.reduce(0) { $0 + $1.size }))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.msSecondaryLabel)
        }
    }

    private func cleanupSummary(_ result: CleanResult) -> some View {
        VStack(spacing: 26) {
            ZStack {
                Circle()
                    .fill((result.isFullSuccess ? Color.msSafe : Color.msCaution).opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: result.isFullSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(result.isFullSuccess ? .msSafe : .msCaution)
            }

            VStack(spacing: 7) {
                Text(result.isFullSuccess ? "Developer Cleanup Complete" : "Cleanup Completed with Some Skips")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(.msLabel)
                Text("Permanently removed \(result.formattedReclaimed) from \(result.successCount) developer items.")
                    .font(.system(size: 14))
                    .foregroundColor(.msSecondaryLabel)
                if result.failureCount > 0 {
                    Text("\(result.failureCount) items could not be removed and were left untouched.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.msCaution)
                }
            }

            HStack(spacing: 14) {
                summaryMetric("Permanently Removed", value: result.formattedReclaimed, icon: "trash.slash.fill", color: .msSafe)
                summaryMetric("Cleaned", value: "\(result.successCount)", icon: "checkmark.shield.fill", color: .msAccent)
                if result.failureCount > 0 {
                    summaryMetric("Skipped", value: "\(result.failureCount)", icon: "exclamationmark.triangle.fill", color: .msCaution)
                }
            }
            .frame(maxWidth: 520)

            Button(action: startScan) {
                Label("Scan Again", systemImage: "arrow.clockwise")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .msCenteredScrollable()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func summaryMetric(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.msSecondaryLabel)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func startScan() {
        Task { await viewModel.scanDeveloperCaches() }
    }
}
