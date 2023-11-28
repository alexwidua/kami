//
// Utils.swift
//
import SwiftUI

class Debouncer {
    var callback: (() -> Void)?
    private var timer: Timer?
    
    func debounce(delay: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { _ in
            self.callback?()
        })
    }
}

func extractScriptID(from string: String) -> String? {
    let pattern = "Script ID: ([A-Z0-9-]+)"
    
    do {
        let regex = try NSRegularExpression(pattern: pattern)
        let nsRange = NSRange(string.startIndex..<string.endIndex, in: string)
        
        if let match = regex.firstMatch(in: string, options: [], range: nsRange) {
            if let range = Range(match.range(at: 1), in: string) {
                let scriptID = String(string[range])
                return scriptID
            }
        }
    } catch {
        print("Regex error: \(error.localizedDescription)")
    }
    
    return nil
}

/* Deduce active screen from mouse cursor position */
func setWindowFrameOriginToCurrentScreen(window: NSWindow) -> Void {
    let mouseLocation = NSEvent.mouseLocation
    if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
        window.setFrameOrigin(NSPoint(x: screen.frame.midX - window.frame.width / 2,
                                      y: screen.frame.midY - window.frame.height / 2))
    }
}

/* Accessibility Permission Stuff */
func checkIfUserHasGrantedAccessibilityPermission() -> Bool {
    let openSystemPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [openSystemPrompt: false]
    let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary?)
    return hasPermission
}

func openAccessibilityPermissionPrompt() -> Void {
    let openSystemPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [openSystemPrompt: true]
    let _ = AXIsProcessTrustedWithOptions(options as CFDictionary?)
}

/* File Path Stuff */
func getFileNameFromPathString(_ string: String) -> String {
    return URL(fileURLWithPath: string).lastPathComponent
}

func getPreferredAppearance(pref: AppearancePreference) -> NSAppearance {
    switch pref {
        case .light:
            return NSAppearance(named: .aqua)!
        case .dark:
            return NSAppearance(named: .darkAqua)!
        case .system:
            return NSApp.effectiveAppearance
    }
}

