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

extension Notification.Name {
    static let openAppWindow = Notification.Name("openMainWindow")
    static let closeAppWindowFromShortcut = Notification.Name("closeWindow")
    static let saveFileFromShortcut = Notification.Name("saveFileFromShortcut")
    static let windowDragged = Notification.Name("windowDragged")
    static let windowStyleChangedFromSettings = Notification.Name("windowStyleChanged")
    static let appearanceChangedFromSettings = Notification.Name("appearanceChanged")
}
