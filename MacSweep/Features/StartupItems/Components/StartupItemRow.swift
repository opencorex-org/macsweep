import SwiftUI

public struct StartupItemRow: View {
    public let agent: LaunchAgentInfo
    public let onToggle: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(agent.isEnabled ? Color.msSafe.opacity(0.15) : Color.gray.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: agent.isEnabled ? "bolt.fill" : "bolt.slash")
                    .font(.system(size: 14))
                    .foregroundColor(agent.isEnabled ? .msSafe : .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(agent.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.msLabel)
                    .lineLimit(1)

                Text(agent.url.path)
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { agent.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(.vertical, 6)
    }
}
