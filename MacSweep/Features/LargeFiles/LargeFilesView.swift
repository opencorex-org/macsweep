import SwiftUI

public struct LargeFilesView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @ObservedObject private var permissionManager: PermissionManager
    @StateObject private var viewModel: LargeFilesViewModel
    @State private var showConfirmDialog = false

    public init(environment: AppEnvironment) {
        _permissionManager = ObservedObject(wrappedValue: environment.permissionManager)
        _viewModel = StateObject(wrappedValue: LargeFilesViewModel(service: environment.largeFileService))
    }

    private var headerButtonStartsScan: Bool {
        viewModel.scanResult == nil || viewModel.files.isEmpty
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if !permissionManager.hasFullDiskAccess {
                permissionBanner
                Divider()
            }

            if viewModel.isScanning {
                LargeFileScanProgressView(
                    progress: viewModel.progress,
                    thresholdInMB: viewModel.thresholdInMB
                )
            } else if viewModel.scanResult == nil {
                EmptyStateView(
                    title: "Find Large Files",
                    subtitle: "Scan Desktop, Documents, Downloads, Movies, Music, and Pictures for files above your chosen size.",
                    iconName: "doc.badge.arrow.up.fill",
                    buttonTitle: "Scan Large Files",
                    buttonAction: {
                        Task { await viewModel.scanLargeFiles() }
                    }
                )
            } else if viewModel.files.isEmpty {
                emptyResults
            } else {
                resultsView
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmationDialog(
                title: "Approve Moving Large Files to Trash?",
                message: "You are approving \(viewModel.selectedCount) selected file\(viewModel.selectedCount == 1 ? "" : "s") (\(ByteFormatter.format(viewModel.selectedBytes))) to be moved to the macOS Trash. You can restore them until Trash is emptied.",
                confirmTitle: "Approve & Move to Trash",
                isDestructive: true,
                onConfirm: {
                    showConfirmDialog = false
                    Task { await viewModel.removeSelectedFiles() }
                },
                onCancel: {
                    showConfirmDialog = false
                }
            )
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Large Files Finder")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.msLabel)
                Text("Find, inspect, and safely manage files consuming substantial disk space")
                    .font(.system(size: 12))
                    .foregroundColor(.msSecondaryLabel)
            }

            Spacer()

            Picker("Threshold", selection: $viewModel.thresholdInMB) {
                Text("> 50 MB").tag(Int64(50))
                Text("> 100 MB").tag(Int64(100))
                Text("> 500 MB").tag(Int64(500))
                Text("> 1 GB").tag(Int64(1_000))
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            .disabled(viewModel.isScanning)

            PrimaryButton(
                title: headerButtonStartsScan ? "Scan Large Files" : "Move Selected (\(ByteFormatter.format(viewModel.selectedBytes)))",
                iconName: headerButtonStartsScan ? "magnifyingglass" : "trash.fill",
                isLoading: viewModel.isScanning || viewModel.isCleaning
            ) {
                if headerButtonStartsScan {
                    Task { await viewModel.scanLargeFiles() }
                } else {
                    showConfirmDialog = true
                }
            }
            .disabled(!headerButtonStartsScan && viewModel.selectedCount == 0)
        }
        .padding(16)
        .background(Color.msSecondaryBackground)
    }

    private var permissionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.trianglebadge.exclamationmark")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Full Disk Access Recommended")
                    .font(.system(size: 12, weight: .semibold))
                Text("Without access, macOS may skip protected folders and results can be incomplete.")
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

    private var emptyResults: some View {
        let inaccessibleCount = viewModel.scanResult?.inaccessibleRoots.count ?? 0
        return EmptyStateView(
            title: "Large File Scan Complete",
            subtitle: inaccessibleCount == 0
                ? "No files were found above \(viewModel.thresholdInMB) MB in the scanned folders."
                : "No files were found, but \(inaccessibleCount) folder\(inaccessibleCount == 1 ? " was" : "s were") inaccessible. Grant Full Disk Access and scan again for complete results.",
            iconName: inaccessibleCount == 0 ? "checkmark.shield.fill" : "lock.trianglebadge.exclamationmark",
            buttonTitle: "Scan Again",
            buttonAction: {
                Task { await viewModel.scanLargeFiles() }
            }
        )
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                resultStat(title: "Files Found", value: "\(viewModel.files.count)", icon: "doc.on.doc", color: .blue)
                resultStat(title: "Total Size", value: ByteFormatter.format(viewModel.totalBytes), icon: "internaldrive", color: .orange)
                resultStat(title: "Selected", value: ByteFormatter.format(viewModel.selectedBytes), icon: "checkmark.circle", color: .green)

                Spacer()

                Button("Select All") { viewModel.selectAll() }
                    .buttonStyle(.borderless)
                Button("Deselect All") { viewModel.deselectAll() }
                    .buttonStyle(.borderless)
            }
            .font(.system(size: 11, weight: .medium))
            .padding(16)

            if let message = viewModel.lastActionMessage {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.managementFailures.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    Text(message)
                    if !viewModel.managementFailures.isEmpty {
                        Text("\(viewModel.managementFailures.count) could not be moved.")
                    }
                    Spacer()
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(viewModel.managementFailures.isEmpty ? .green : .orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background((viewModel.managementFailures.isEmpty ? Color.green : Color.orange).opacity(0.08))
            }

            Divider()

            List {
                ForEach(viewModel.files) { file in
                    LargeFileRow(
                        file: file,
                        onToggle: { viewModel.toggleFileSelection(file) },
                        onOpen: { viewModel.openFile(file) },
                        onReveal: { viewModel.revealInFinder(file) }
                    )
                }
            }
            .listStyle(.inset)
        }
    }

    private func resultStat(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.msLabel)
            }
        }
    }
}

private struct LargeFileScanProgressView: View {
    let progress: LargeFileScanProgress?
    let thresholdInMB: Int64

    private var fraction: Double { progress?.fractionCompleted ?? 0 }

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(fraction, 0.05))
                    .stroke(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .frame(width: 120, height: 120)

            VStack(spacing: 10) {
                Text("Searching for Files Above \(thresholdInMB) MB")
                    .font(.system(size: 20, weight: .bold))

                Text("\(progress?.scannedFilesCount ?? 0) files inspected • \(progress?.foundFilesCount ?? 0) large files found")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)

                if let path = progress?.currentPath, !path.isEmpty {
                    Text(path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.msSecondaryLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 560)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08))
                        Capsule()
                            .fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * CGFloat(fraction))
                    }
                }
                .frame(width: 520, height: 8)

                Text("\(Int(fraction * 100))% of folders completed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.msSecondaryLabel)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
