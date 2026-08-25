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

                            HStack(spacing: 5) {
                                Circle()
                                    .fill(Color.msSafe)
                                    .frame(width: 7, height: 7)
                                Text("System Optimal")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.msSafe)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.msSafe.opacity(0.12))
                            .cornerRadius(12)
                        }

                        Text("Real-time system health, storage allocation, and maintenance tools")
                            .font(.system(size: 12))
                            .foregroundColor(.msSecondaryLabel)
                    }

                    Spacer()

                    SecondaryButton(title: "Full Scan", iconName: "sparkles") {
                        coordinator.navigate(to: .smartScan)
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
                        onScanAction: {
                            Task {
                                await viewModel.runQuickScan()
                            }
                        }
                    )
                }
                .fixedSize(horizontal: false, vertical: true)

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
                            action: { coordinator.navigate(to: .smartScan) }
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
                    HealthBadge(icon: "shield.checkmark.fill", color: .green, title: "Safety Guard", subtitle: "SIP Protection Enforced")
                    HealthBadge(icon: "memorychip.fill", color: .blue, title: "Memory Engine", subtitle: "Real-time Monitor")
                    HealthBadge(icon: "lock.applewatch", color: .orange, title: "Privacy Suite", subtitle: "Browser Data Safe")
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .onAppear {
            viewModel.refreshDiskSpace()
        }
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
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.msLabel)
                Text(subtitle)
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
