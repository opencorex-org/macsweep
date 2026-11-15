import SwiftUI

public struct OptimiseView: View {
    @StateObject private var viewModel: OptimiseViewModel
    @State private var showingConfirmation = false

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: OptimiseViewModel(environment: environment))
    }

    public var body: some View {
        Group {
            if viewModel.isScanning {
                ScanProgressView(
                    progress: viewModel.scanProgress,
                    onStop: viewModel.stopScan
                )
            } else if viewModel.isCleaning {
                CleaningProgressView(
                    progress: viewModel.cleanProgress,
                    title: "Optimising Your Mac",
                    subtitle: "Removing approved clutter while protecting system and personal files…"
                )
            } else if let result = viewModel.lastCleanResult {
                ScanSummaryView(result: result, verifiedBytesFreed: viewModel.verifiedBytesFreed) {
                    Task { await viewModel.analyse() }
                }
            } else if !viewModel.hasAnalysed {
                welcomeView
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "Your Mac Is Optimised",
                    subtitle: "No safe optimisation recommendations were found.",
                    iconName: "checkmark.seal.fill",
                    buttonTitle: "Analyse Again",
                    buttonAction: { Task { await viewModel.analyse() } }
                )
            } else {
                recommendationsView
            }
        }
        .sheet(isPresented: $showingConfirmation) {
            ConfirmationDialog(
                title: "Apply Selected Optimisations?",
                message: "Preview: \(viewModel.safeSelectedCount) safe and \(viewModel.cautionSelectedCount) caution items, totalling \(ByteFormatter.format(viewModel.selectedBytes)). Cleanup is permanent and cannot be recovered; protected paths and ignored items remain excluded.",
                confirmTitle: "Optimise \(ByteFormatter.format(viewModel.selectedBytes))",
                isDestructive: true,
                onConfirm: {
                    showingConfirmation = false
                    Task { await viewModel.cleanSelected() }
                },
                onCancel: { showingConfirmation = false }
            )
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.msAccent.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(.msAccent)
            }

            VStack(spacing: 7) {
                Text("Optimise Your Mac")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.msLabel)
                Text("Find safe opportunities to reclaim storage and remove accumulated clutter.")
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                featureCard("Safe Analysis", icon: "checkmark.shield.fill", tint: .green)
                featureCard("Smart Selection", icon: "slider.horizontal.3", tint: .blue)
                featureCard("Full Review", icon: "list.bullet.rectangle", tint: .orange)
            }
            .frame(maxWidth: 620)

            PrimaryButton(title: "Analyse Mac", iconName: "wand.and.stars") {
                Task { await viewModel.analyse() }
            }
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var recommendationsView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Optimisation Recommendations")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.msLabel)
                        Text("Review each recommendation before applying changes.")
                            .font(.system(size: 11))
                            .foregroundColor(.msSecondaryLabel)
                    }
                    Spacer()
                    SecondaryButton(title: "Analyse Again", iconName: "arrow.clockwise") {
                        Task { await viewModel.analyse() }
                    }
                    Button("Safe Clean", systemImage: "checkmark.shield.fill") {
                        viewModel.selectRecommended()
                        showingConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.items.contains { $0.risk == .safe })
                    PrimaryButton(
                        title: "Optimise \(ByteFormatter.format(viewModel.selectedBytes))",
                        iconName: "wand.and.stars"
                    ) {
                        showingConfirmation = true
                    }
                    .disabled(viewModel.selectedCount == 0)
                }

                HStack(spacing: 12) {
                    metricCard("Reclaimable", value: ByteFormatter.format(viewModel.reclaimableBytes), icon: "internaldrive.fill", tint: .msAccent)
                    metricCard("Recommendations", value: "\(viewModel.items.count)", icon: "lightbulb.fill", tint: .orange)
                    metricCard("Categories", value: "\(viewModel.categoryCount)", icon: "square.grid.2x2.fill", tint: .purple)
                }

                HStack(spacing: 14) {
                    Button("Recommended") { viewModel.selectRecommended() }
                    Button("Select All") { viewModel.selectAll() }
                    Button("Deselect All") { viewModel.deselectAll() }
                    Spacer()
                    Text("\(viewModel.selectedCount) selected • \(ByteFormatter.format(viewModel.selectedBytes))")
                        .foregroundColor(.msSecondaryLabel)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11, weight: .medium))
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            List {
                let grouped = Dictionary(grouping: viewModel.items, by: \.category)
                ForEach(grouped.keys.sorted { $0.displayName < $1.displayName }, id: \.self) { category in
                    let categoryItems = grouped[category] ?? []
                    Section {
                        ForEach(categoryItems) { item in
                            ScanResultRow(item: item) { viewModel.toggle(item) }
                        }
                    } header: {
                        OptimiseCategoryHeader(category: category, items: categoryItems, viewModel: viewModel)
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private func featureCard(_ title: String, icon: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.msLabel)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            }
    }

    private func metricCard(_ title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 13, weight: .bold))
                Text(LocalizedStringKey(title)).font(.system(size: 10)).foregroundColor(.msSecondaryLabel)
            }
            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.msBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct OptimiseCategoryHeader: View {
    let category: CleanupCategory
    let items: [CleanupItem]
    @ObservedObject var viewModel: OptimiseViewModel

    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { items.allSatisfy(\.isSelected) },
                set: { viewModel.setSelection(for: category, isSelected: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)
            Image(systemName: category.iconName).foregroundColor(category.tintColor)
            Text(LocalizedStringKey(category.displayName)).font(.system(size: 12, weight: .bold))
            Spacer()
            Text(ByteFormatter.format(items.reduce(0) { $0 + $1.size }))
                .font(.system(size: 11))
                .foregroundColor(.msSecondaryLabel)
        }
    }
}
