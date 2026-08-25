import SwiftUI

public struct DuplicatesView: View {
    @StateObject private var viewModel = DuplicatesViewModel()
    @State private var showConfirmDialog = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Duplicates Finder")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)

                    Text("Find and remove identical file copies across folders")
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                if !viewModel.groups.isEmpty {
                    Menu("Auto Select") {
                        Button("Keep Newest (Select Older)") {
                            viewModel.selectAllExceptNewest()
                        }
                        Button("Keep Oldest (Select Newer)") {
                            viewModel.selectAllExceptOldest()
                        }
                    }
                    .menuStyle(.borderlessButton)

                    PrimaryButton(
                        title: "Remove (\(ByteFormatter.format(viewModel.selectedBytesCount)))",
                        iconName: "trash.fill",
                        isLoading: viewModel.isCleaning
                    ) {
                        showConfirmDialog = true
                    }
                    .disabled(viewModel.selectedFilesCount == 0)
                } else {
                    PrimaryButton(
                        title: "Scan Duplicates",
                        iconName: "magnifyingglass",
                        isLoading: viewModel.isScanning
                    ) {
                        Task { await viewModel.scanForDuplicates() }
                    }
                }
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if viewModel.isScanning {
                LoadingView(title: "Scanning for Duplicate Files...", subtitle: "Calculating content hashes")
            } else if viewModel.groups.isEmpty {
                EmptyStateView(
                    title: "No Duplicates Scanned",
                    subtitle: "Scan your user folders to locate duplicate documents, photos, or downloads.",
                    iconName: "doc.on.doc.fill",
                    buttonTitle: "Start Duplicates Scan",
                    buttonAction: {
                        Task { await viewModel.scanForDuplicates() }
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.groups) { group in
                            DuplicateGroupView(group: group) { fileID in
                                viewModel.toggleFileSelection(groupID: group.id, fileID: fileID)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmationDialog(
                title: "Delete Duplicate Files?",
                message: "Are you sure you want to delete \(viewModel.selectedFilesCount) duplicate files (\(ByteFormatter.format(viewModel.selectedBytesCount)))?",
                confirmTitle: "Delete Duplicates",
                isDestructive: true,
                onConfirm: {
                    showConfirmDialog = false
                    Task { await viewModel.deleteSelectedDuplicates() }
                },
                onCancel: {
                    showConfirmDialog = false
                }
            )
        }
    }
}
