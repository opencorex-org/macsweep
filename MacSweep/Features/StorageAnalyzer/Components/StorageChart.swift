import SwiftUI

public struct StorageChart: View {
    public let node: StorageNode

    private var colors: [Color] {
        [.blue, .purple, .teal, .indigo, .orange, .pink, .green, .mint]
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Distribution")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.msLabel)

            GeometryReader { geo in
                HStack(spacing: 2) {
                    let topChildren = Array(node.children.sorted(by: { $0.size > $1.size }).prefix(6))
                    let parentSize = max(Double(node.size), 1)

                    ForEach(Array(topChildren.enumerated()), id: \.element.id) { index, child in
                        let ratio = Double(child.size) / parentSize
                        let width = max(geo.size.width * CGFloat(ratio), 4)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(colors[index % colors.count])
                            .frame(width: width)
                            .help("\(child.name): \(child.formattedSize)")
                    }
                }
            }
            .frame(height: 16)

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                let topChildren = Array(node.children.sorted(by: { $0.size > $1.size }).prefix(6))
                ForEach(Array(topChildren.enumerated()), id: \.element.id) { index, child in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colors[index % colors.count])
                            .frame(width: 8, height: 8)
                        Text(child.name)
                            .font(.system(size: 11))
                            .foregroundColor(.msLabel)
                            .lineLimit(1)
                        Spacer()
                        Text(child.formattedSize)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.msSecondaryLabel)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.msSecondaryBackground)
        .cornerRadius(10)
    }
}
