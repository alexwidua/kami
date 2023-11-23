//
// Custom window controller to
//
// • Implement a Spotlight-esque window that disappears on click-outside
// • Settings window
//

import SwiftUI

func getAppearanceFromAppStorage() -> NSAppearance {
    let rawValue = UserDefaults.standard.string(forKey: appearancePreferenceStorageKey) ?? AppearancePreference.system.rawValue
    let value = AppearancePreference(rawValue: rawValue)!
    return getPreferredAppearance(pref: value)
  
}
/* Main App Window. Closes on blur */
class AppWindow: NSWindow, NSWindowDelegate {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [ .titled, .resizable, .fullSizeContentView], backing: backing, defer: flag)
        self.isMovable = true
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        self.isReleasedWhenClosed = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.delegate = self
    }
    
    /* Close app window on click outside (aka. when window loses focus) */
    func windowDidResignKey(_ notification: Notification) {
        self.close()
    }
}

func setupAppWindow() -> AppWindow {
    let window = AppWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false)
    let contentView = ContentView(windowRef: window)
        .frame(minWidth: 500)
        .frame(minHeight: 300, maxHeight: 2000)
        .edgesIgnoringSafeArea(.top)
    window.appearance = getAppearanceFromAppStorage()
    window.contentView = NSHostingView(rootView: contentView)
    return window
}


/* Settings Window */
var settingsWindow: SettingsWindow?

class SettingsWindow: NSWindow, NSWindowDelegate {
    @ObservedObject  var appState = AppState.shared
    var openAppWindowAfterClose: Bool = false
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool, openAppWindowAfterClose: Bool) {
        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .fullSizeContentView], backing: backing, defer: flag)
        self.isReleasedWhenClosed = false
        self.delegate = self
        self.openAppWindowAfterClose = openAppWindowAfterClose
    }
    
    func windowWillClose(_ notification: Notification) {
        if(openAppWindowAfterClose) {
            NotificationCenter.default.post(name: .openAppWindow, object: nil)
        }
        settingsWindow = nil
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.removeWindowsItem(sender)
        return true
    }
}

func setupSettingsWindow(openAppWindowAfterClose: Bool) -> SettingsWindow {
    let window = SettingsWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false, openAppWindowAfterClose: openAppWindowAfterClose)
    let contentView = SettingsWindowView(windowRef: window).frame(width: 600)
    window.appearance = getAppearanceFromAppStorage()
    window.contentView = NSHostingView(rootView: contentView)
    window.center()
    window.makeKeyAndOrderFront(nil)
    setWindowFrameOriginToCurrentScreen(window: window)
    return window
}
