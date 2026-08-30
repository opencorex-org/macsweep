import SwiftUI

public struct SidebarView: View {
    @Binding public var selection: NavigationItem?
    @EnvironmentObject private var environment: AppEnvironment

    @State private var diskSpace: DiskSpace?

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
            diskSpace = try? environment.diskSpaceService.getDiskSpace()
        }
    }
}
