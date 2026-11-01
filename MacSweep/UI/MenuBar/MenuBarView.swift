import AppKit
import SwiftUI

public struct MenuBarView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var diskSpace: DiskSpace?

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let diskSpace {
                Label("\(diskSpace.formattedAvailable) available", systemImage: "internaldrive")
                if let change = environment.storageHistoryService.freeSpaceChange {
                    Text("90-day change: \(change >= 0 ? "+" : "")\(ByteFormatter.format(change))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Button(environment.automationService.isRunning ? "Scanning…" : "Run Maintenance Now") {
                Task { await environment.automationService.runNow(); refresh() }
            }
            .disabled(environment.automationService.isRunning)
            Button("Open MacSweep") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
            }
            Divider()
            Button("Quit MacSweep") { NSApplication.shared.terminate(nil) }
        }
        .padding(8)
        .frame(width: 230)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        diskSpace = try? environment.diskSpaceService.getDiskSpace()
        if let diskSpace { environment.storageHistoryService.record(diskSpace) }
    }
}
