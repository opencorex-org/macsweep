import AppKit
import Combine
import SwiftUI

public struct MaintenanceSettings: View {
    @EnvironmentObject private var environment: AppEnvironment
    @ObservedObject var viewModel: SettingsViewModel
    @State private var ruleName = ""
    @State private var rulePath = ""
    @State private var ruleExtension = ""
    @State private var ruleAge = 30
    @State private var exportMessage: String?
    @State private var ruleRefresh = UUID()

    public var body: some View {
        VStack(spacing: 16) {
            automationCard
            exclusionsCard
            rulesCard
            historyCard
            diagnosticsCard
        }
        .id(ruleRefresh)
        .onReceive(environment.customRuleService.objectWillChange) { _ in
            ruleRefresh = UUID()
        }
    }

    private var automationCard: some View {
        SettingsCard(title: "Automation", subtitle: "Run maintenance without opening the main window", icon: "calendar.badge.clock", tint: .teal) {
            VStack(spacing: 12) {
                HStack {
                    Text("Schedule")
                    Spacer()
                    Picker("Schedule", selection: Binding(get: { viewModel.scanSchedule }, set: {
                        viewModel.scanSchedule = $0
                        environment.automationService.configure()
                    })) {
                        ForEach(ScanSchedule.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .frame(width: 130)
                }
                HStack {
                    Text("Scan profile")
                    Spacer()
                    Picker("Profile", selection: Binding(get: { viewModel.scanProfile }, set: { viewModel.scanProfile = $0 })) {
                        ForEach(ScanProfile.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                if viewModel.scanProfile == .custom {
                    Toggle("Include developer cache sources", isOn: $viewModel.customProfileDeveloperSources)
                    Toggle("Include enabled custom rules", isOn: $viewModel.customProfileRules)
                }
                Toggle("Automatically clean safety-approved items", isOn: $viewModel.scheduledAutoClean)
                Toggle("Analyze external drives when connected", isOn: $viewModel.externalDriveAutoScan)
                HStack {
                    Text(viewModel.scanProfile.detail)
                        .font(.system(size: 10))
                        .foregroundColor(.msSecondaryLabel)
                    Spacer()
                    Button(environment.automationService.isRunning ? "Running…" : "Run Now") {
                        Task { await environment.automationService.runNow() }
                    }
                    .disabled(environment.automationService.isRunning)
                }
            }
            .font(.system(size: 12))
        }
    }

    private var exclusionsCard: some View {
        SettingsCard(title: "Scan Exclusions", subtitle: "Protected folders are omitted from every scan", icon: "folder.badge.minus", tint: .orange) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(environment.exclusionService.paths, id: \.self) { path in
                    HStack {
                        Image(systemName: "folder.fill").foregroundColor(.orange)
                        Text(path).font(.system(size: 10)).lineLimit(1)
                        Spacer()
                        Button { environment.exclusionService.remove(path) } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.plain)
                    }
                }
                Button("Add Folder…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = true
                    if panel.runModal() == .OK { panel.urls.forEach(environment.exclusionService.add) }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var rulesCard: some View {
        SettingsCard(title: "Custom Cleanup Rules", subtitle: "Find old files under a user-selected folder; custom matches are never preselected", icon: "slider.horizontal.3", tint: .purple) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(environment.customRuleService.rules) { rule in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { rule.isEnabled },
                            set: { enabled in
                                guard let index = environment.customRuleService.rules.firstIndex(where: { $0.id == rule.id }) else { return }
                                environment.customRuleService.rules[index].isEnabled = enabled
                            }
                        )).labelsHidden()
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.name).font(.system(size: 11, weight: .semibold))
                            Text("\(rule.path) • .\(rule.fileExtension.isEmpty ? "any" : rule.fileExtension) • older than \(rule.minimumAgeDays)d")
                                .font(.system(size: 9)).foregroundColor(.msSecondaryLabel).lineLimit(1)
                        }
                        Spacer()
                        Button { environment.customRuleService.rules.removeAll { $0.id == rule.id } } label: { Image(systemName: "trash") }
                            .buttonStyle(.plain)
                    }
                }
                Divider()
                HStack {
                    TextField("Rule name", text: $ruleName)
                    TextField("Folder path", text: $rulePath)
                    TextField("Extension", text: $ruleExtension).frame(width: 80)
                    Stepper("\(ruleAge)d", value: $ruleAge, in: 1...365)
                    Button("Add") {
                        guard !ruleName.isEmpty, !rulePath.isEmpty else { return }
                        environment.customRuleService.add(name: ruleName, path: rulePath, fileExtension: ruleExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")), minimumAgeDays: ruleAge)
                        ruleName = ""; rulePath = ""; ruleExtension = ""
                    }
                }
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 10))
            }
        }
    }

    private var historyCard: some View {
        SettingsCard(title: "Cleanup History", subtitle: "The latest 200 maintenance operations", icon: "clock.arrow.circlepath", tint: .blue) {
            VStack(alignment: .leading, spacing: 8) {
                if environment.cleanupHistoryService.entries.isEmpty {
                    Text("No cleanups recorded yet.").foregroundColor(.msSecondaryLabel)
                } else {
                    ForEach(environment.cleanupHistoryService.entries.prefix(8)) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.source).font(.system(size: 11, weight: .semibold))
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 9)).foregroundColor(.msSecondaryLabel)
                            }
                            Spacer()
                            Text(ByteFormatter.format(entry.reclaimedBytes)).font(.system(size: 11, weight: .bold))
                            Text("\(entry.successCount) cleaned / \(entry.failureCount) failed").font(.system(size: 9)).foregroundColor(.msSecondaryLabel)
                        }
                    }
                    Button("Clear History", role: .destructive) { environment.cleanupHistoryService.clear() }
                        .buttonStyle(.borderless)
                }
            }
            .font(.system(size: 11))
        }
    }

    private var diagnosticsCard: some View {
        SettingsCard(title: "Diagnostics", subtitle: "Export a privacy-safe JSON report without file paths", icon: "stethoscope", tint: .green) {
            HStack {
                Text(exportMessage ?? "Includes app, OS, cleanup, and storage summary information.")
                    .font(.system(size: 10)).foregroundColor(.msSecondaryLabel)
                Spacer()
                Button("Export Report…") {
                    do {
                        let url = try environment.diagnosticReportService.export(history: environment.cleanupHistoryService.entries, exclusions: environment.exclusionService.paths, storage: environment.storageHistoryService.snapshots)
                        exportMessage = "Saved \(url.lastPathComponent)"
                    } catch { exportMessage = error.localizedDescription }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
