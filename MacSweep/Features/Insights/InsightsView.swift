import AppKit
import Combine
import SwiftUI

@MainActor
private final class InsightsViewModel: ObservableObject {
    @Published var insights: [MaintenanceInsight] = []
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var errorMessage: String?

    private let environment: AppEnvironment

    init(environment: AppEnvironment) { self.environment = environment }

    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        errorMessage = nil
        async let items = environment.maintenanceInsightsService.scan(ignoredPaths: environment.ignoreListStore.paths)
        async let duplicates = environment.maintenanceInsightsService.duplicatePhotos(ignoredPaths: environment.ignoreListStore.paths)
        insights = await items
        duplicateGroups = await duplicates
        isScanning = false
    }
}

public struct InsightsView: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @ObservedObject private var ignoreList: IgnoreListStore
    @StateObject private var viewModel: InsightsViewModel
    @State private var selectedKind: MaintenanceInsight.Kind?

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: InsightsViewModel(environment: environment))
        self.ignoreList = environment.ignoreListStore
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if viewModel.isScanning && viewModel.insights.isEmpty {
                LoadingView(title: "Analysing storage safely…")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        summary
                        filters
                        if filteredInsights.isEmpty {
                            EmptyStateView(title: "No Matching Insights", subtitle: "Run an analysis or choose another category.", iconName: "checkmark.seal.fill")
                                .frame(height: 230)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredInsights) { item in insightRow(item) }
                            }
                        }
                        duplicateSection
                        ignoreSection
                    }
                    .padding(18)
                }
            }
        }
        .background(Color.msBackground)
        .task { if viewModel.insights.isEmpty { await viewModel.scan() } }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg.rectangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.msAccent)
                .frame(width: 42, height: 42)
                .background(Color.msAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("Storage Insights").font(.system(size: 18, weight: .bold))
                Text("Review recent files, caches, installers, apps, photos, and snapshots")
                    .font(.system(size: 11)).foregroundColor(.msSecondaryLabel)
            }
            Spacer()
            Button("Safe Clean", systemImage: "checkmark.shield.fill") { coordinator.navigate(to: .optimise) }
                .buttonStyle(.borderedProminent)
            Button("Analyse", systemImage: "arrow.clockwise") { Task { await viewModel.scan() } }
                .disabled(viewModel.isScanning)
        }
        .padding(16)
        .background(Color.msSecondaryBackground)
    }

    private var summary: some View {
        HStack(spacing: 12) {
            insightMetric("Review Items", "\(viewModel.insights.count)", "list.bullet.rectangle", .blue)
            insightMetric("Potential Space", ByteFormatter.format(viewModel.insights.reduce(0) { $0 + $1.size }), "internaldrive", .orange)
            insightMetric("Duplicate Photos", "\(viewModel.duplicateGroups.count) groups", "photo.on.rectangle.angled", .pink)
            insightMetric("Ignored", "\(ignoreList.paths.count + ignoreList.categories.count)", "eye.slash", .gray)
        }
    }

    private var filters: some View {
        Picker("Category", selection: $selectedKind) {
            Text("All").tag(nil as MaintenanceInsight.Kind?)
            ForEach(MaintenanceInsight.Kind.allCases, id: \.self) { kind in Text(kind.title).tag(kind as MaintenanceInsight.Kind?) }
        }
        .pickerStyle(.segmented)
    }

    private var filteredInsights: [MaintenanceInsight] {
        guard let selectedKind else { return viewModel.insights }
        return viewModel.insights.filter { $0.kind == selectedKind }
    }

    private func insightRow(_ item: MaintenanceInsight) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: item.kind))
                .foregroundColor(color(for: item.kind))
                .frame(width: 34, height: 34)
                .background(color(for: item.kind).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                Text(item.detail).font(.system(size: 10)).foregroundColor(.msSecondaryLabel).lineLimit(1)
            }
            Spacer()
            if let date = item.date { Text(date.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 10)).foregroundColor(.msSecondaryLabel) }
            if item.size > 0 { Text(ByteFormatter.format(item.size)).font(.system(size: 11, weight: .medium)).frame(width: 76, alignment: .trailing) }
            Menu {
                if let url = item.url {
                    Button("Reveal in Finder", systemImage: "folder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                    Button("Ignore", systemImage: "eye.slash") { ignoreList.add(url); Task { await viewModel.scan() } }
                }
                if item.kind == .snapshot {
                    Button("Open Time Machine Settings", systemImage: "clock.arrow.circlepath") { openTimeMachineSettings() }
                }
            } label: { Image(systemName: "ellipsis.circle") }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
        }
        .padding(11)
        .background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private var duplicateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Duplicate Photos", systemImage: "photo.stack").font(.system(size: 14, weight: .bold))
            Text("Content hashes are compared; originals are never removed automatically.")
                .font(.system(size: 10)).foregroundColor(.msSecondaryLabel)
            ForEach(viewModel.duplicateGroups.prefix(8)) { group in
                HStack {
                    Text("\(group.files.count) identical files").font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text(ByteFormatter.format(group.wastedSpace)).foregroundColor(.msSecondaryLabel)
                    Button("Review") { coordinator.navigate(to: .duplicates) }.buttonStyle(.borderless)
                }
                .padding(10).background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 9))
            }
        }
    }

    private var ignoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Ignore List", systemImage: "eye.slash.fill").font(.system(size: 14, weight: .bold))
                Spacer()
                Button("Add Folder…", systemImage: "plus") { addIgnoredFolder() }.buttonStyle(.borderless)
            }
            ForEach(ignoreList.paths, id: \.self) { path in
                HStack { Text(path).font(.system(size: 10)).lineLimit(1); Spacer(); Button("Remove") { ignoreList.remove(path); Task { await viewModel.scan() } }.buttonStyle(.borderless) }
                    .padding(8).background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 8))
            }
            Menu("Ignored Categories", systemImage: "square.grid.2x2") {
                ForEach(CleanupCategory.allCases) { category in
                    Button {
                        ignoreList.toggle(category)
                    } label: {
                        Label(category.displayName, systemImage: ignoreList.categories.contains(category) ? "checkmark" : category.iconName)
                    }
                }
            }
            .menuStyle(.borderlessButton)
            if !ignoreList.categories.isEmpty {
                Text(ignoreList.categories.map(\.displayName).sorted().joined(separator: " • "))
                    .font(.system(size: 10)).foregroundColor(.msSecondaryLabel)
            }
        }
    }

    private func insightMetric(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        HStack { Image(systemName: icon).foregroundColor(tint); VStack(alignment: .leading) { Text(value).font(.system(size: 13, weight: .bold)); Text(title).font(.system(size: 9)).foregroundColor(.msSecondaryLabel) }; Spacer() }
            .padding(10).frame(maxWidth: .infinity).background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private func addIgnoredFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = true; panel.allowsMultipleSelection = true
        if panel.runModal() == .OK { panel.urls.forEach(ignoreList.add); Task { await viewModel.scan() } }
    }

    private func openTimeMachineSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Time-Machine-Settings.extension") { NSWorkspace.shared.open(url) }
    }

    private func icon(for kind: MaintenanceInsight.Kind) -> String {
        switch kind { case .recentFile: "clock.badge"; case .installer: "shippingbox"; case .screenshot: "camera.viewfinder"; case .appCache: "app.badge"; case .browserCache: "globe"; case .unusedApp: "app.dashed"; case .snapshot: "clock.arrow.circlepath" }
    }
    private func color(for kind: MaintenanceInsight.Kind) -> Color {
        switch kind { case .recentFile: .blue; case .installer: .orange; case .screenshot: .pink; case .appCache: .indigo; case .browserCache: .purple; case .unusedApp: .red; case .snapshot: .teal }
    }
}
