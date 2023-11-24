import SwiftUI

struct MouseEvt: ViewModifier {
    var onMouseDown: () -> Void
    var onMouseUp: () -> Void
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onMouseDown()
                    })
                    .onEnded({ _ in
                        onMouseUp()
                    })
            )
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
