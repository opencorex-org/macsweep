import SwiftUI

public struct StorageTreeView: View {
    public let node: StorageNode
    @Binding public var selectedNode: StorageNode?

    public var body: some View {
        List {
            let sortedChildren = node.children.sorted(by: { $0.size > $1.size })
            ForEach(sortedChildren) { child in
                StorageRow(
                    node: child,
                    isSelected: selectedNode?.id == child.id,
                    onSelect: {
                        selectedNode = child
                    }
                )
            }
        }
        .listStyle(.plain)
    }
}
