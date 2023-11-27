import SwiftUI

/* Subclassed TextView to override right-click ctx menu of the default NSTextView */
class CustomTextView: NSTextView {
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
               menu.addItem(withTitle: "Cut", action: #selector(cut(_:)), keyEquivalent: "x")
               menu.addItem(withTitle: "Copy", action: #selector(copy(_:)), keyEquivalent: "c")
               menu.addItem(withTitle: "Paste", action: #selector(paste(_:)), keyEquivalent: "v")
               return menu
    }
}
