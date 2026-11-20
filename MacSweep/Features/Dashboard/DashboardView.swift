import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @StateObject private var viewModel: DashboardViewModel

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(environment: environment))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("MacSweep Overview")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.msLabel)
                        }

                        Text("Real-time system health, storage allocation, and maintenance tools")
                            .font(.system(size: 12))
                            .foregroundColor(.msSecondaryLabel)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Link(destination: AppConstants.App.repositoryURL) {
                            Image("GitHubMark")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .padding(6.5)
                                .foregroundColor(.msSecondaryLabel)
                                .background(Color.primary.opacity(0.06), in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .hoverEffect(scale: 1.02)
                        .help("View MacSweep on GitHub")
                        .accessibilityLabel("View MacSweep source code on GitHub")

                        Link(destination: AppConstants.App.sponsorURL) {
                            Label("Sponsor", systemImage: "heart.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .foregroundColor(.pink)
                                .background(Color.pink.opacity(0.1), in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.pink.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .hoverEffect(scale: 1.02)
                        .help("Sponsor MacSweep on GitHub")

                        SecondaryButton(title: "Full Scan", iconName: "sparkles") {
                            coordinator.startFullScan()
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Top Hero Row: StorageCard & CleanableCard with EQUAL HEIGHTS
                HStack(spacing: 16) {
                    StorageCard(diskSpace: viewModel.diskSpace)

                    CleanableCard(
                        cleanableBytes: viewModel.cleanableBytes,
                        itemsCount: viewModel.scannedItemsCount,
                        isScanning: viewModel.isScanning,
                        onScanAction: { coordinator.startSmartScan() }
                    )
                }
                .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    ZStack {
                        Circle().stroke(Color.msSeparator.opacity(0.4), lineWidth: 7)
                        Circle().trim(from: 0, to: Double(viewModel.healthScore) / 100)
                            .stroke(healthColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(viewModel.healthScore)").font(.system(size: 18, weight: .bold))
                    }
                    .frame(width: 58, height: 58)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Mac Health Score").font(.system(size: 14, weight: .bold))
                        Text(healthDescription).font(.system(size: 11)).foregroundColor(.msSecondaryLabel)
                    }
                    Spacer()
                    Button("View Insights", systemImage: "waveform.path.ecg") { coordinator.navigate(to: .insights) }
                        .buttonStyle(.bordered)
                }
                .padding(14)
                .background(Color.msSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))

                // Quick Tools Section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Quick Tools")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.msLabel)

                        Spacer()
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        QuickActionCard(
                            title: "Smart Scan",
                            subtitle: "Scan system cache, logs, and temp files",
                            iconName: "sparkles",
                            iconColor: .purple,
                            categoryTag: "System",
                            action: { coordinator.startSmartScan() }
                        )

                        QuickActionCard(
                            title: "Developer Cleaner",
                            subtitle: "Xcode, Node, Gradle & Docker caches",
                            iconName: "hammer.fill",
                            iconColor: .indigo,
                            categoryTag: "Dev Tools",
                            action: { coordinator.navigate(to: .developerCleaner) }
                        )

                        QuickActionCard(
                            title: "Large & Old Files",
                            subtitle: "Locate space-consuming files",
                            iconName: "doc.badge.arrow.up.fill",
                            iconColor: .red,
                            categoryTag: "Storage",
                            action: { coordinator.navigate(to: .largeFiles) }
                        )

                        QuickActionCard(
                            title: "Duplicates Finder",
                            subtitle: "Find and delete duplicate files",
                            iconName: "doc.on.doc.fill",
                            iconColor: .pink,
                            categoryTag: "Duplicates",
                            action: { coordinator.navigate(to: .duplicates) }
                        )
                    }
                }

                // System Health Features Banner
                HStack(spacing: 12) {
                    HealthBadge(icon: "checkmark.shield.fill", color: viewModel.healthStatus.1, title: "System Health", subtitle: viewModel.healthStatus.0)
                    HealthBadge(icon: "bolt.fill", color: viewModel.highImpactStartupCount == 0 ? .green : .orange, title: "Startup Load", subtitle: "\(viewModel.highImpactStartupCount) high-impact items")
                    HealthBadge(icon: "clock.arrow.circlepath", color: .blue, title: "Storage History", subtitle: "\(viewModel.storageSnapshots.count) daily samples")
                }
                .padding(.top, 4)

                if viewModel.storageSnapshots.count > 1 {
                    StorageTrendCard(snapshots: viewModel.storageSnapshots)
                }
            }
            .padding(20)
        }
        .onAppear {
            viewModel.refreshDiskSpace()
        }
    }

    private var healthColor: Color {
        if viewModel.healthScore >= 80 { return .green }
        if viewModel.healthScore >= 55 { return .orange }
        return .red
    }

    private var healthDescription: String {
        if viewModel.healthScore >= 80 { return "Storage levels look healthy. Keep reviewing recommendations regularly." }
        if viewModel.healthScore >= 55 { return "Some storage maintenance is recommended." }
        return "Storage needs attention soon to keep macOS responsive."
    }
}

private struct StorageTrendCard: View {
    let snapshots: [StorageSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Free Space Trend").font(.system(size: 13, weight: .bold))
            GeometryReader { geometry in
                let values = snapshots.suffix(30)
                let maximum = values.map(\.freeBytes).max() ?? 1
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(values)) { sample in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.75))
                            .frame(height: max(3, geometry.size.height * CGFloat(Double(sample.freeBytes) / Double(maximum))))
                            .help("\(sample.date.formatted(date: .abbreviated, time: .omitted)): \(ByteFormatter.format(sample.freeBytes)) free")
                    }
                }
            }
            .frame(height: 70)
        }
        .padding(14)
        .background(Color.msSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct HealthBadge: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.msLabel)
                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.msSecondaryBackground.opacity(0.6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
}
