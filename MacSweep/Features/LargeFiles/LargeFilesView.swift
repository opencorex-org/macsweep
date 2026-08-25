import SwiftUI

public struct LargeFilesView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel: LargeFilesViewModel
    @State private var showConfirmDialog = false

    public init(environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: LargeFilesViewModel(service: environment.largeFileService))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Large Files Finder")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)
                    Text("Find files consuming substantial disk space")
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                Picker("Threshold", selection: $viewModel.thresholdInMB) {
                    Text("> 50 MB").tag(Int64(50))
                    Text("> 100 MB").tag(Int64(100))
                    Text("> 500 MB").tag(Int64(500))
                    Text("> 1 GB").tag(Int64(1024))
                }
                .pickerStyle(.menu)
                .frame(width: 120)

                PrimaryButton(
                    title: viewModel.files.isEmpty ? "Scan Large Files" : "Clean Selected (\(ByteFormatter.format(viewModel.selectedBytes)))",
                    iconName: viewModel.files.isEmpty ? "magnifyingglass" : "trash.fill",
                    isLoading: viewModel.isScanning || viewModel.isCleaning
                ) {
                    if viewModel.files.isEmpty {
                        Task { await viewModel.scanLargeFiles() }
                    } else {
                        showConfirmDialog = true
                    }
                }
                .disabled(!viewModel.files.isEmpty && viewModel.selectedCount == 0)
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if viewModel.isScanning {
                LoadingView(title: "Searching Large Files...", subtitle: "Traversing user directories for files > \(viewModel.thresholdInMB) MB")
            } else if viewModel.files.isEmpty {
                EmptyStateView(
                    title: "No Large Files Found",
                    subtitle: "Scan your system to discover files taking up large amounts of disk space.",
                    iconName: "doc.badge.arrow.up.fill",
                    buttonTitle: "Scan Large Files",
                    buttonAction: {
                        Task { await viewModel.scanLargeFiles() }
                    }
                )
            } else {
                List {
                    ForEach(viewModel.files) { file in
                        LargeFileRow(file: file) {
                            viewModel.toggleFileSelection(file)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmationDialog(
                title: "Delete Large Files?",
                message: "Are you sure you want to delete \(viewModel.selectedCount) selected files (\(ByteFormatter.format(viewModel.selectedBytes)))?",
                confirmTitle: "Delete Now",
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
}
