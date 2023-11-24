import SwiftUI

// ┌───────────────────────┐
// │ Splash Window         │
// └───────────────────────┘
var splashWindow: SplashWindow?
class SplashWindow: NSWindow, NSWindowDelegate {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [ .titled, .closable, .fullSizeContentView], backing: backing, defer: flag)
        self.isReleasedWhenClosed = false
        self.titlebarSeparatorStyle = .none
        self.titlebarAppearsTransparent = true
        self.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        splashWindow = nil
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.removeWindowsItem(sender)
        return true
    }
}

// ┌───────────────────────┐
// │ Main App Window       │
// └───────────────────────┘
class AppWindow: NSWindow, NSWindowDelegate {
    @ObservedObject  var appState = AppState.shared
    var url: URL?
    var isPinned: Bool = false
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool, url: URL) {
        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: backing, defer: flag)
        self.isReleasedWhenClosed = true
        self.titlebarSeparatorStyle = .none
        self.titlebarAppearsTransparent = true
        self.isMovable = true
        self.isMovableByWindowBackground = true

        if (getWindowStyleFromAppStorage() == .transient) {
            applyTransientWindowStyle()
        }
       
        self.delegate = self
        self.url = url
    }
    
    func windowWillClose(_ notification: Notification) {
        if let url = url {
            appState.removeWindowReference(for: url)
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.removeWindowsItem(sender)
        return true
    }
    
    /* Close transient window on click outside (aka. when window loses focus) */
    func windowDidResignKey(_ notification: Notification) {
        if(isPinned) { return }
        if(getWindowStyleFromAppStorage() == .windowed) {return}
        self.close()
    }
    
    /* Pin window when dragged */
    override func mouseDragged(with event: NSEvent) {
           super.mouseDragged(with: event)
        if(!isPinned) {
            NotificationCenter.default.post(name: .windowDragged, object: nil)
            self.pinWindow()
            self.isPinned = true
        }
       }
    
    func pinWindow() -> Void {
        self.isPinned = true
    }
    
    func applyTransientWindowStyle() -> Void {
        self.titleVisibility = .hidden
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    func applyWindowedWindowStyle() -> Void {
        self.titleVisibility = .visible
        self.standardWindowButton(.closeButton)?.isHidden = false
        self.standardWindowButton(.miniaturizeButton)?.isHidden = false
        self.standardWindowButton(.zoomButton)?.isHidden = false
    }
}

// ┌───────────────────────┐
// │ Settings Window       │
// └───────────────────────┘
var settingsWindow: SettingsWindow?

class SettingsWindow: NSWindow, NSWindowDelegate {
    @ObservedObject  var appState = AppState.shared
    var openAppWindowAfterClose: Bool = false
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .fullSizeContentView], backing: backing, defer: flag)
        self.isReleasedWhenClosed = false
        self.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.removeWindowsItem(sender)
        return true
    }
}

// ┌───────────────────────┐
// │ Loading Window        │
// └───────────────────────┘
class LoadingWindow: NSWindow, NSWindowDelegate {
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
}

// ┌───────────────────────┐
// │  Notification Window  │
// └───────────────────────┘
class NotificationWindow: NSWindow, NSWindowDelegate {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [ .titled, .fullSizeContentView], backing: backing, defer: flag)
        self.isMovable = true
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = true
        self.delegate = self
    }
}

/* Create Windows */
func setupWindow(_ window: NSWindow) -> Void {
    window.center()
    window.makeKeyAndOrderFront(nil)
    setWindowFrameOriginToCurrentScreen(window: window)
}

func createSplashWindow() -> Void {
    if(splashWindow == nil) {
        let window = SplashWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false)
        let contentView = SplashView().frame(width: 600)
        window.appearance = getAppearanceFromAppStorage()
        window.contentView = NSHostingView(rootView: contentView)
        setupWindow(window)
        splashWindow = window
    }
    else {
        splashWindow!.makeKeyAndOrderFront(nil)
    }
}

func createAppWindow(url: URL) -> AppWindow {
    let window = AppWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false, url: url)
    let contentView = ContentView(window: window, url: url).frame(width: 600)
    window.appearance = getAppearanceFromAppStorage()
    window.contentView = NSHostingView(rootView: contentView)
    setupWindow(window)
    return window
}

func createSettingsWindow() -> Void {
    if(settingsWindow == nil) {
        let window = SettingsWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false)
        let contentView = SettingsWindowView(windowRef: window).frame(width: 600)
        window.appearance = getAppearanceFromAppStorage()
        window.contentView = NSHostingView(rootView: contentView)
        setupWindow(window)
        settingsWindow = window
    }
    else {
        settingsWindow!.makeKeyAndOrderFront(nil)
    }
}


func createLoadingWindow() -> LoadingWindow {
    let window = LoadingWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false)
    let contentView = LoadingView().frame(width: 200, height: 200)
    window.appearance = getAppearanceFromAppStorage()
    window.contentView = NSHostingView(rootView: contentView)
    setupWindow(window)
    return window
}

func createAccessibilityRequestWindow() -> Void {
    let window = NotificationWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false)
    let contentView = AccessibilityRequestView(window: window)
    window.contentView = NSHostingView(rootView: contentView)
    setupWindow(window)
}

func createPatchErrorWindow(message: String) -> Void {
    let window = NotificationWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false)
    let contentView = PatchErrorView(window: window, message: message)
    window.contentView = NSHostingView(rootView: contentView)
    setupWindow(window)
}

/* Misc */
func getAppearanceFromAppStorage() -> NSAppearance {
    let rawValue = UserDefaults.standard.string(forKey: appearancePreferenceStorageKey) ?? AppearancePreference.system.rawValue
    let value = AppearancePreference(rawValue: rawValue)!
    return getPreferredAppearance(pref: value)
}

func getWindowStyleFromAppStorage() -> WindowStylePreference {
    let rawValue = UserDefaults.standard.string(forKey: windowStylePreferenceStorageKey) ?? DEFAULT_WINDOW_STYLE_PREFERENCE.rawValue
    let value = WindowStylePreference(rawValue: rawValue)!
    return value
}
