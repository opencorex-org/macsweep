import AppKit
import Combine
import SwiftUI

public struct SidebarView: View {
    @Binding public var selection: NavigationItem?
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.scenePhase) private var scenePhase

    @State private var diskSpace: DiskSpace?
    private let storageRefreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(selection: Binding<NavigationItem?>) {
        self._selection = selection
    }

    public var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(NavigationGroup.allCases) { group in
                    Section(header: Text(group.rawValue).font(.system(size: 11, weight: .bold)).foregroundColor(.msSecondaryLabel)) {
                        ForEach(NavigationItem.allCases.filter { $0.group == group }) { item in
                            NavigationLink(value: item) {
                                Label {
                                    Text(item.displayName)
                                        .font(.system(size: 13, weight: .medium))
                                } icon: {
                                    Image(systemName: item.iconName)
                                        .foregroundColor(selection == item ? .msAccent : .msSecondaryLabel)
                                }
                            }
                            .tag(item)
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Disk Usage Footer
            if let diskSpace = diskSpace {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "internaldrive.fill")
                            .foregroundColor(.msAccent)
                        Text(diskSpace.volumeName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.msLabel)
                        Spacer()
                        Text("\(diskSpace.formattedAvailable) free")
                            .font(.system(size: 11))
                            .foregroundColor(.msSecondaryLabel)
                            .contentTransition(.numericText())
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                            Capsule()
                                .fill(diskSpace.usedPercentage > 0.9 ? Color.msHighRisk : (diskSpace.usedPercentage > 0.75 ? Color.msCaution : Color.msAccent))
                                .frame(
                                    width: geometry.size.width * CGFloat(min(max(diskSpace.usedPercentage, 0), 1))
                                )
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(diskSpace.formattedUsed) used")
                        Spacer()
                        Text("Total \(diskSpace.formattedTotal)")
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                }
                .padding(12)
                .background(Color.msSecondaryBackground.opacity(0.6))
            }
        }
        .task {
            refreshDiskSpace()
        }
        .onReceive(storageRefreshTimer) { _ in
            guard scenePhase == .active else { return }
            refreshDiskSpace()
        }
        .onReceive(environment.cleanupHistoryService.objectWillChange) { _ in
            refreshDiskSpace()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                refreshDiskSpace()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshDiskSpace() }
        }
    }

    private func refreshDiskSpace() {
        guard let updated = try? environment.diskSpaceService.getDiskSpace() else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            diskSpace = updated
        }
    }
}
