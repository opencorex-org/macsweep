import SwiftUI

public struct UninstallerView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @ObservedObject private var permissionManager: PermissionManager
    @StateObject private var viewModel: UninstallerViewModel
    @State private var showConfirmDialog = false
    @State private var showPermissionDialog = false

    public init(environment: AppEnvironment) {
        _permissionManager = ObservedObject(wrappedValue: environment.permissionManager)
        _viewModel = StateObject(wrappedValue: UninstallerViewModel(service: environment.applicationService))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("App Uninstaller")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)
                    Text("Completely remove applications along with their hidden leftovers & caches")
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                SecondaryButton(title: "Scan Apps", iconName: "arrow.clockwise") {
                    Task { await viewModel.loadApplications() }
                }
                .disabled(viewModel.isLoading || viewModel.isUninstalling)
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if !permissionManager.hasFullDiskAccess {
                permissionBanner
                Divider()
            }

            if viewModel.isUninstalling, let app = viewModel.uninstallingApp {
                ApplicationUninstallProgressView(app: app, progress: viewModel.uninstallProgress)
            } else if let result = viewModel.uninstallResult, let app = viewModel.uninstallingApp {
                ApplicationUninstallResultView(app: app, result: result) {
                    viewModel.dismissUninstallResult()
                }
            } else if viewModel.isLoading {
                LoadingView(title: "Scanning Installed Applications...")
            } else if viewModel.applications.isEmpty {
                EmptyStateView(
                    title: "Scan Applications",
                    subtitle: "Locate installed macOS apps to see their complete disk footprint and leftovers.",
                    iconName: "app.badge.checkmark",
                    buttonTitle: "Scan Applications",
                    buttonAction: {
                        Task { await viewModel.loadApplications() }
                    }
                )
            } else {
                HSplitView {
                    // Left App List
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.msSecondaryLabel)
                            TextField("Search apps...", text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(6)
                        .padding(8)

                        List(viewModel.filteredApplications) { app in
                            ApplicationRow(
                                app: app,
                                isSelected: viewModel.selectedApp?.id == app.id,
                                onSelect: {
                                    viewModel.selectedApp = app
                                }
                            )
                        }
                        .listStyle(.plain)
                    }
                    .frame(minWidth: 260, maxWidth: 360)

                    // Right Detail
                    if let selectedApp = viewModel.selectedApp {
                        ApplicationDetailView(app: selectedApp) {
                            if permissionManager.hasFullDiskAccess {
                                showConfirmDialog = true
                            } else {
                                showPermissionDialog = true
                            }
                        }
                    } else {
                        EmptyStateView(
                            title: "Select an Application",
                            subtitle: "Choose an application from the list to view detailed files and uninstall options.",
                            iconName: "app.dashed"
                        )
                    }
                }
            }
        }
        .onAppear {
            if viewModel.applications.isEmpty {
                Task { await viewModel.loadApplications() }
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            if let selectedApp = viewModel.selectedApp {
                ConfirmationDialog(
                    title: "Approve Uninstalling \(selectedApp.name)?",
                    message: "MacSweep will move the application and \(selectedApp.leftovers.count) associated item\(selectedApp.leftovers.count == 1 ? "" : "s") (\(selectedApp.formattedTotalSize)) to the macOS Trash. You can restore them until Trash is emptied.",
                    confirmTitle: "Approve & Move to Trash",
                    isDestructive: true,
                    onConfirm: {
                        showConfirmDialog = false
                        Task { await viewModel.uninstallApplication(selectedApp) }
                    },
                    onCancel: {
                        showConfirmDialog = false
                    }
                )
            }
        }
        .sheet(isPresented: $showPermissionDialog) {
            ConfirmationDialog(
                title: "Full Disk Access Required",
                message: "MacSweep needs Full Disk Access before uninstalling so it can move the application and its protected containers together without leaving a partial uninstall.",
                confirmTitle: "Open Privacy Settings",
                cancelTitle: "Not Now",
                isDestructive: false,
                onConfirm: {
                    showPermissionDialog = false
                    permissionManager.requestFullDiskAccess()
                },
                onCancel: {
                    showPermissionDialog = false
                }
            )
        }
    }

    private var permissionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.trianglebadge.exclamationmark")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Full Disk Access Required for Complete Uninstall")
                    .font(.system(size: 12, weight: .semibold))
                Text("Grant access before uninstalling protected application containers and support files.")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
            }

            Spacer()

            Button("Open Privacy Settings") {
                permissionManager.requestFullDiskAccess()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.08))
    }
}

private struct ApplicationUninstallProgressView: View {
    let app: ApplicationInfo
    let progress: ApplicationUninstallProgress?

    private var fraction: Double { progress?.fractionCompleted ?? 0 }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            VStack(spacing: 24) {
                ApplicationIconView(bundleURL: app.bundleURL, size: 88)

                VStack(spacing: 8) {
                    Text("Uninstalling \(app.name)…")
                        .font(.system(size: 22, weight: .bold))

                    Text(progress?.currentItemName ?? "Preparing uninstall…")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.msSecondaryLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 520)
                }

                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.08))
                            Capsule()
                                .fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * CGFloat(fraction))
                        }
                    }
                    .frame(width: 500, height: 9)

                    HStack {
                        Text("\(progress?.completedItemsCount ?? 0) of \(progress?.totalItemsCount ?? 1) items processed")
                        Spacer()
                        Text("\(Int(fraction * 100))% • \(elapsedText(at: context.date))")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)
                    .frame(width: 500)
                }

                HStack(spacing: 7) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.orange)
                    Text("Files are being moved to Trash and remain recoverable.")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func elapsedText(at date: Date) -> String {
        let elapsed = max(0, date.timeIntervalSince(progress?.startedAt ?? date))
        return String(format: "%.1fs", elapsed)
    }
}

private struct ApplicationUninstallResultView: View {
    let app: ApplicationInfo
    let result: ApplicationUninstallResult
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
                ApplicationIconView(bundleURL: app.bundleURL, size: 84)
                Image(systemName: result.isFullSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(result.isFullSuccess ? .green : .orange)
                    .background(Color.msBackground.clipShape(Circle()))
            }

            VStack(spacing: 7) {
                Text(result.isFullSuccess ? "Uninstall Complete" : "Uninstall Completed with Issues")
                    .font(.system(size: 22, weight: .bold))
                Text(result.appBundleMovedToTrash
                    ? "\(result.applicationName) was moved to Trash."
                    : "The application bundle could not be moved to Trash.")
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
            }

            HStack(spacing: 14) {
                resultStat(title: "Items Moved", value: "\(result.movedItemsCount)/\(result.totalItemsCount)", icon: "trash.fill", color: .green)
                resultStat(title: "Moved Size", value: ByteFormatter.format(result.movedBytes), icon: "internaldrive", color: .blue)
                resultStat(title: "Process Time", value: String(format: "%.1fs", result.duration), icon: "clock.fill", color: .purple)
            }
            .frame(maxWidth: 560)

            if !result.failures.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Could Not Move")
                        .font(.system(size: 12, weight: .bold))
                    ForEach(Array(result.failures.enumerated()), id: \.offset) { _, failure in
                        Text("• \(failure.url.lastPathComponent): \(failure.reason)")
                            .font(.system(size: 10))
                            .foregroundColor(.msSecondaryLabel)
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .frame(maxWidth: 560, alignment: .leading)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(8)
            }

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resultStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(value)
                .font(.system(size: 17, weight: .bold))
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.msSecondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.msSecondaryBackground)
        .cornerRadius(9)
    }
}

private struct ApplicationUninstallProgressView: View {
    let app: ApplicationInfo
    let progress: ApplicationUninstallProgress?

    private var fraction: Double { progress?.fractionCompleted ?? 0 }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            VStack(spacing: 24) {
                ApplicationIconView(bundleURL: app.bundleURL, size: 88)

                VStack(spacing: 8) {
                    Text("Uninstalling \(app.name)…")
                        .font(.system(size: 22, weight: .bold))

                    Text(progress?.currentItemName ?? "Preparing uninstall…")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.msSecondaryLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 520)
                }

                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.08))
                            Capsule()
                                .fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * CGFloat(fraction))
                        }
                    }
                    .frame(width: 500, height: 9)

                    HStack {
                        Text("\(progress?.completedItemsCount ?? 0) of \(progress?.totalItemsCount ?? 1) items processed")
                        Spacer()
                        Text("\(Int(fraction * 100))% • \(elapsedText(at: context.date))")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)
                    .frame(width: 500)
                }

                HStack(spacing: 7) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.orange)
                    Text("Files are being moved to Trash and remain recoverable.")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func elapsedText(at date: Date) -> String {
        let elapsed = max(0, date.timeIntervalSince(progress?.startedAt ?? date))
        return String(format: "%.1fs", elapsed)
    }
}

private struct ApplicationUninstallResultView: View {
    let app: ApplicationInfo
    let result: ApplicationUninstallResult
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
                ApplicationIconView(bundleURL: app.bundleURL, size: 84)
                Image(systemName: result.isFullSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(result.isFullSuccess ? .green : .orange)
                    .background(Color.msBackground.clipShape(Circle()))
            }

            VStack(spacing: 7) {
                Text(result.isFullSuccess ? "Uninstall Complete" : "Uninstall Completed with Issues")
                    .font(.system(size: 22, weight: .bold))
                Text(result.appBundleMovedToTrash
                    ? "\(result.applicationName) was moved to Trash."
                    : "The application bundle could not be moved to Trash.")
                    .font(.system(size: 13))
                    .foregroundColor(.msSecondaryLabel)
            }

            HStack(spacing: 14) {
                resultStat(title: "Items Moved", value: "\(result.movedItemsCount)/\(result.totalItemsCount)", icon: "trash.fill", color: .green)
                resultStat(title: "Moved Size", value: ByteFormatter.format(result.movedBytes), icon: "internaldrive", color: .blue)
                resultStat(title: "Process Time", value: String(format: "%.1fs", result.duration), icon: "clock.fill", color: .purple)
            }
            .frame(maxWidth: 560)

            if !result.failures.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Could Not Move")
                        .font(.system(size: 12, weight: .bold))
                    ForEach(Array(result.failures.enumerated()), id: \.offset) { _, failure in
                        Text("• \(failure.url.lastPathComponent): \(failure.reason)")
                            .font(.system(size: 10))
                            .foregroundColor(.msSecondaryLabel)
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .frame(maxWidth: 560, alignment: .leading)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(8)
            }

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resultStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(value)
                .font(.system(size: 17, weight: .bold))
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.msSecondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.msSecondaryBackground)
        .cornerRadius(9)
    }
}
