import SwiftUI

public struct StartupItemsView: View {
    @StateObject private var viewModel = StartupItemsViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Startup Items")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)
                    Text("Manage background LaunchAgents that run when logging into macOS")
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                SecondaryButton(title: "Refresh", iconName: "arrow.clockwise") {
                    viewModel.loadStartupItems()
                }
            }
            .padding(16)
            .background(Color.msSecondaryBackground)

            Divider()

            if viewModel.isLoading {
                LoadingView(title: "Loading Startup Items...")
            } else if viewModel.agents.isEmpty {
                EmptyStateView(
                    title: "No Startup LaunchAgents Found",
                    subtitle: "There are currently no custom LaunchAgent plists found in ~/Library/LaunchAgents.",
                    iconName: "bolt.slash"
                )
            } else {
                List {
                    ForEach(viewModel.agents) { agent in
                        StartupItemRow(agent: agent) {
                            viewModel.toggleAgent(agent)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .onAppear {
            viewModel.loadStartupItems()
        }
    }
}
