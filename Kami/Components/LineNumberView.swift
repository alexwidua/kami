//
// LineNumber component for the code editor,
// Code by Yichi Zhang, https://github.com/yichizhang/NSTextView-LineNumberView/tree/master (2016)
// (Code comments by original author)
//

import SwiftUI


var LNVIEW_ASSOC_OBJ_KEY: UInt8 = 0
var TEXT_INSET = 8.0

extension NSTextView {
    var lineNumberView:LineNumberRulerView {
        get {
            return objc_getAssociatedObject(self, &LNVIEW_ASSOC_OBJ_KEY) as! LineNumberRulerView
        }
        set {
            objc_setAssociatedObject(self, &LNVIEW_ASSOC_OBJ_KEY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func setUpLineNumberView(gutterWidth: CGFloat = 40) {
        if font == nil {
            font = NSFont.systemFont(ofSize: 16)
        }
        
        if let scrollView = enclosingScrollView {
            lineNumberView = LineNumberRulerView(textView: self, gutterWidth: gutterWidth)
            scrollView.verticalRulerView = lineNumberView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
            scrollView.backgroundColor = .red
        }
        
        // set up observer to respond to window resize events
        postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(frameDidChange), name: NSView.frameDidChangeNotification, object: self)
    }
    
    @objc func frameDidChange(notification: NSNotification) {
        lineNumberView.needsDisplay = true
    }
    
}

class LineNumberRulerView: NSRulerView {
    var font: NSFont! {
        didSet {
            self.needsDisplay = true
        }
    }
    
    var gutterWidth: CGFloat = 40 {
        didSet {
            self.needsDisplay = true
        }
    }
    
    init(textView: NSTextView, gutterWidth: CGFloat) {
        self.gutterWidth = gutterWidth
        super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerView.Orientation.verticalRuler)
        self.font = textView.font ?? NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        self.clientView = textView
        self.clipsToBounds = true
        self.ruleThickness = gutterWidth
        
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        
        if let textView = self.clientView as? NSTextView {
            if let layoutManager = textView.layoutManager {
                
                let relativePoint = self.convert(NSZeroPoint, from: textView)
                let lineNumberAttributes: [NSAttributedString.Key: Any] = [.font: textView.font ?? NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                                                                               .foregroundColor: NSColor.gray]
                let drawLineNumber = { (lineNumberString:String, y:CGFloat) -> Void in
                    let attString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
                    let x = (self.gutterWidth - 5.0) - attString.size().width
                    attString.draw(at: NSPoint(x: x, y: relativePoint.y + y + TEXT_INSET))
                }
                
                let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)
                let firstVisibleGlyphCharacterIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
                
                let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])
                // The line number for the first visible line
                var lineNumber = newLineRegex.numberOfMatches(in: textView.string, options: [], range: NSMakeRange(0, firstVisibleGlyphCharacterIndex)) + 1
                
                var glyphIndexForStringLine = visibleGlyphRange.location
                
                // Go through each line in the string.
                while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
                    
                    // Range of current line in the string.
                    let characterRangeForStringLine = (textView.string as NSString).lineRange(
                        for: NSMakeRange( layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0 )
                    )
                    let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)
                    
                    var glyphIndexForGlyphLine = glyphIndexForStringLine
                    var glyphLineCount = 0
                    
                    while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
                        // See if the current line in the string spread across
                        // several lines of glyphs
                        var effectiveRange = NSMakeRange(0, 0)
                        
                        // Range of current "line of glyphs". If a line is wrapped,
                        // then it will have more than one "line of glyphs"
                        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                        
                        if glyphLineCount > 0 {
                            drawLineNumber(" ", lineRect.minY)
                        } else {
                            drawLineNumber("\(lineNumber)", lineRect.minY)
                        }
                        
                        // Move to next glyph line
                        glyphLineCount += 1
                        glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
                    }
                    
                    glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
                    lineNumber += 1
                }
                
                // Draw line number for the extra line at the end of the text
                if layoutManager.extraLineFragmentTextContainer != nil {
                    drawLineNumber("\(lineNumber)", layoutManager.extraLineFragmentRect.minY)
                }
            }
        }
    }
}
