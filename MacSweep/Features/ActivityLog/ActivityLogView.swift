import AppKit
import SwiftUI
import UniformTypeIdentifiers

public struct ActivityLogView: View {
    @ObservedObject private var store: ActivityLogStore
    @State private var searchText = ""
    @State private var selectedKind: ActivityLogEntry.Kind?
    @State private var showingClearConfirmation = false

    public init(store: ActivityLogStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if store.entries.isEmpty {
                EmptyStateView(
                    title: "No Activity Yet",
                    subtitle: "Completed scans, cleanups, uninstalls, and app moves will appear here.",
                    iconName: "clock.arrow.circlepath"
                )
            } else if filteredEntries.isEmpty {
                EmptyStateView(
                    title: "No Matching Activity",
                    subtitle: "Try a different search or activity type.",
                    iconName: "line.3.horizontal.decrease.circle"
                )
            } else {
                List(filteredEntries) { entry in
                    ActivityLogRow(entry: entry)
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                store.delete(entry)
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .searchable(text: $searchText, prompt: "Search activity")
        .background(Color.msBackground)
        .confirmationDialog(
            "Clear all activity history?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) { store.clear() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.msAccent.opacity(0.14))
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.msAccent)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity History")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)
                    Text("Review completed MacSweep operations")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                Picker("Activity type", selection: $selectedKind) {
                    Text("All Activity").tag(nil as ActivityLogEntry.Kind?)
                    ForEach(ActivityLogEntry.Kind.allCases) { kind in
                        Label {
                            Text(LocalizedStringKey(kind.title))
                        } icon: {
                            Image(systemName: kind.icon)
                        }
                            .tag(kind as ActivityLogEntry.Kind?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)

                Button("Clear", systemImage: "trash") {
                    showingClearConfirmation = true
                }
                .disabled(store.entries.isEmpty)

                Button("Export", systemImage: "square.and.arrow.up") { exportReport() }
                    .disabled(store.entries.isEmpty)
            }

            HStack(spacing: 12) {
                ActivitySummaryCard(
                    title: "Operations",
                    value: "\(store.entries.count)",
                    icon: "checkmark.circle.fill",
                    tint: .green
                )
                ActivitySummaryCard(
                    title: "Data Removed",
                    value: ByteFormatter.format(reclaimedBytes),
                    icon: "internaldrive.fill",
                    tint: .msAccent
                )
                ActivitySummaryCard(
                    title: "Latest Activity",
                    value: latestActivityText,
                    icon: "clock.fill",
                    tint: .orange
                )
            }
        }
        .padding(16)
        .background(Color.msSecondaryBackground)
    }

    private var filteredEntries: [ActivityLogEntry] {
        store.entries.filter { entry in
            let matchesKind = selectedKind == nil || entry.kind == selectedKind
            let matchesSearch = searchText.isEmpty
                || entry.title.localizedCaseInsensitiveContains(searchText)
                || entry.detail.localizedCaseInsensitiveContains(searchText)
            return matchesKind && matchesSearch
        }
    }

    private var reclaimedBytes: Int64 {
        store.entries
            .filter { $0.kind == .cleanup || $0.kind == .uninstall }
            .reduce(0) { $0 + $1.byteCount }
    }

    private var latestActivityText: String {
        guard let date = store.entries.first?.date else { return "—" }
        return date.formatted(.relative(presentation: .named))
    }

    private func exportReport() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MacSweep Activity Report.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? store.csvReport().write(to: url, atomically: true, encoding: .utf8)
    }
}

private struct ActivitySummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.msLabel)
                    .lineLimit(1)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.msBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.msSeparator.opacity(0.45), lineWidth: 1)
        }
    }
}

private struct ActivityLogRow: View {
    let entry: ActivityLogEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(statusColor)
                .frame(width: 34, height: 34)
                .background(statusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.msLabel)
                Text(entry.detail)
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                HStack(spacing: 8) {
                    if entry.itemCount > 0 {
                        Label("\(entry.itemCount)", systemImage: "doc.on.doc")
                    }
                    if entry.byteCount > 0 {
                        Text(ByteFormatter.format(entry.byteCount))
                    }
                    if entry.duration > 0 {
                        Text(entry.duration.formatted(.number.precision(.fractionLength(1))) + "s")
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.msSecondaryLabel)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var statusColor: Color {
        switch entry.status {
        case .success: .msSafe
        case .warning: .msCaution
        case .failure: .msHighRisk
        }
    }
}
