import SwiftUI

public struct HoverModifier: ViewModifier {
    @State private var isHovered = false
    var scale: CGFloat = 1.02
    var hoverColor: Color? = nil

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .background(hoverColor != nil && isHovered ? hoverColor : Color.clear)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public extension View {
    func hoverEffect(scale: CGFloat = 1.02, hoverColor: Color? = nil) -> some View {
        modifier(HoverModifier(scale: scale, hoverColor: hoverColor))
    }
}
