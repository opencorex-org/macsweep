import SwiftUI

public struct StorageCard: View {
    public let diskSpace: DiskSpace?

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 34, height: 34)

                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("System Storage")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.msLabel)

                    Text(diskSpace?.volumeName ?? "Macintosh HD")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                }

                Spacer()

                if let diskSpace = diskSpace {
                    Text("\(diskSpace.formattedAvailable) Free")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }

            Spacer()

            // Visual Progress Bar
            if let diskSpace = diskSpace {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(diskSpace.formattedUsed) Used")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.msLabel)

                        Spacer()

                        Text("\(Int(diskSpace.usedPercentage * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(diskSpace.usedPercentage > 0.9 ? .msHighRisk : .msAccent)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 8)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .indigo],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * CGFloat(diskSpace.usedPercentage), 8), height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("Capacity")
                            .font(.system(size: 11))
                            .foregroundColor(.msSecondaryLabel)

                        Spacer()

                        Text("Total \(diskSpace.formattedTotal)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.msSecondaryLabel)
                    }
                }
            } else {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .cardStyle()
    }
}
