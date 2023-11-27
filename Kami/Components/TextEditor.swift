//
// Custom Text Editor
// We use our own AppKit implementation (over SwiftUI's TextEditor)
// to get more control about the text behaviour, paddings etc.
//

import SwiftUI

enum TextStyle {
    case sansLarge
    case sansBody
    case monoBody
}

struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    
    var disabled: Bool = false
    var textStyle: TextStyle = .sansLarge
    var textColor: Color = .white
    
    var textViewAttributes: [NSAttributedString.Key:Any] {
        var font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        var lineSpacing: CGFloat = 0
        
        switch textStyle {
        case .sansLarge:
            font = NSFont.systemFont(ofSize: 16, weight: .light)
            lineSpacing = 4
        case .sansBody:
            font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .light)
        case .monoBody:
            font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
        
        return [
            .font: font,
            .paragraphStyle: {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = lineSpacing
                return paragraph
            }()
        ]
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let textView = CustomTextView()
        
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: textView.bounds.width, height: CGFloat.infinity)
        textView.textContainer?.widthTracksTextView = true
        
        textView.isEditable = !disabled
        textView.allowsUndo = true
        
        // padding
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 8
        
        textView.backgroundColor = .clear
        textView.typingAttributes = textViewAttributes
        
        if disabled {
            textView.textColor = NSColor(textColor).withAlphaComponent(0.5)
        }
        else {
            textView.textColor = NSColor(textColor)
        }
  
        // disable rich text formatting
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.enabledTextCheckingTypes = 0;
        textView.isRichText = false
        
        // make text scrollable
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        
        scrollView.automaticallyAdjustsContentInsets = false
        
        textView.delegate = context.coordinator
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            let cursorPosition = textView.selectedRange
            textView.string = text
            textView.setSelectedRange(cursorPosition)
        }
        
        textView.isEditable = !disabled
        textView.typingAttributes = textViewAttributes
        
        if disabled {
            textView.textColor = NSColor(textColor).withAlphaComponent(0.5)
        }
        else {
            textView.textColor = NSColor(textColor)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextEditor
        
        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let newText = textView.string
            if newText != self.parent.text {
                // Perform the update on the main thread to avoid threading issues
                DispatchQueue.main.async {
                    self.parent.text = newText
                }
            }
        }
        
    }
}

// add .modifiers 
extension CustomTextEditor {
    func disabled(_ bool: Bool) -> CustomTextEditor {
        var view = self
        view.disabled = bool
        return view
    }
    func textStyle(_ style: TextStyle) -> CustomTextEditor {
        var view = self
        view.textStyle = style
        return view
    }
    func textColor(_ color: Color) -> CustomTextEditor {
        var view = self
        view.textColor = color
        return view
    }
}

