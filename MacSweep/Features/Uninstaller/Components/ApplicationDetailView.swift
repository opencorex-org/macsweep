import SwiftUI

public struct ApplicationDetailView: View {
    public let app: ApplicationInfo
    public let onUninstall: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.msAccent.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: "app.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.msAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.msLabel)

                    Text(app.bundleIdentifier)
                        .font(.system(size: 12))
                        .foregroundColor(.msSecondaryLabel)

                    Text("Total Size: \(app.formattedTotalSize)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.msAccent)
                }

                Spacer()
            }
            .padding(16)
            .background(Color.msSecondaryBackground)
            .cornerRadius(12)

            // Installed Component Breakdown
            VStack(alignment: .leading, spacing: 10) {
                Text("Installed Files & Leftovers")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.msLabel)

                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                            .foregroundColor(.blue)
                        Text("Application Bundle")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text(ByteFormatter.format(app.bundleSize))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(6)

                    ForEach(app.leftovers) { leftover in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(leftover.name)
                                    .font(.system(size: 12, weight: .medium))
                                Text(leftover.type.rawValue)
                                    .font(.system(size: 10))
                                    .foregroundColor(.msSecondaryLabel)
                            }
                            Spacer()
                            Text(ByteFormatter.format(leftover.size))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(6)
                    }
                }
            }

            Spacer()

            // Uninstall Action
            HStack {
                Spacer()
                Button(action: onUninstall) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Completely Uninstall")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.msHighRisk)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }
}
