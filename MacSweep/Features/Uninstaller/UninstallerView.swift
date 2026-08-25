import SwiftUI

public struct UninstallerView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel: UninstallerViewModel
    @State private var showConfirmDialog = false

    public init(environment: AppEnvironment) {
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
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if viewModel.isLoading {
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
                            showConfirmDialog = true
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
                    title: "Completely Uninstall \(selectedApp.name)?",
                    message: "This action will permanently delete \(selectedApp.name) and all associated cache and configuration files (\(selectedApp.formattedTotalSize)).",
                    confirmTitle: "Uninstall App",
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
    }
}
