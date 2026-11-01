import SwiftUI

public struct PrivacyView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = PrivacyViewModel()
    @State private var showConfirmDialog = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Privacy Cleaner")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)

                    Text("Clear web browser caches, cookies, and tracking artifacts")
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                PrimaryButton(
                    title: viewModel.items.isEmpty ? "Scan Privacy Data" : "Clean Selected (\(ByteFormatter.format(viewModel.selectedBytes)))",
                    iconName: viewModel.items.isEmpty ? "hand.raised.fill" : "trash.fill",
                    isLoading: viewModel.isScanning || viewModel.isCleaning
                ) {
                    if viewModel.items.isEmpty {
                        Task { await viewModel.scanPrivacyItems() }
                    } else {
                        showConfirmDialog = true
                    }
                }
                .disabled(!viewModel.items.isEmpty && viewModel.selectedCount == 0)
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if let message = viewModel.statusMessage {
                Label(message, systemImage: "info.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.isScanning {
                LoadingView(title: "Scanning Browser Data...", subtitle: "Checking Safari, Chrome, Firefox, Arc, Edge, Brave, Opera, and Vivaldi")
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "No Privacy Items Scanned",
                    subtitle: "Protect your privacy by scanning and clearing web browser caches and local cookies.",
                    iconName: "hand.raised.fill",
                    buttonTitle: "Scan Privacy Data",
                    buttonAction: {
                        Task { await viewModel.scanPrivacyItems() }
                    }
                )
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        PrivacyItemRow(item: item) {
                            viewModel.toggleItemSelection(item)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showConfirmDialog) {
            ConfirmationDialog(
                title: "Clean Selected Privacy Items?",
                message: "Are you sure you want to clean \(viewModel.selectedCount) selected privacy items (\(ByteFormatter.format(viewModel.selectedBytes)))?",
                confirmTitle: "Clean Data",
                isDestructive: true,
                onConfirm: {
                    showConfirmDialog = false
                    Task { await viewModel.cleanPrivacyItems(history: environment.cleanupHistoryService, notifications: environment.notificationService) }
                },
                onCancel: {
                    showConfirmDialog = false
                }
            )
        }
    }
}
