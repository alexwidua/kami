//
// WindowController.swift
//
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
        //        self.backgroundColor = .clear
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
        self.isReleasedWhenClosed = false
        self.titlebarSeparatorStyle = .none
        self.titlebarAppearsTransparent = true
        self.isMovable = true
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        
        if (getWindowStyleFromAppStorage() == .pinnable) {
            applyPinnableWindowStyle()
        }
        
        if let windowSizeString = UserDefaults.standard.string(forKey: AppStorageKey.windowSizePref) {
            let windowSize = NSSizeFromString(windowSizeString)
            self.setContentSize(windowSize)
        }
      
        
        self.delegate = self
        self.url = url
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleWindowClose), name: .closeAppWindowFromShortcut, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppearanceChange), name: .appearanceChangedFromSettings, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWindowStyleChange), name: .windowStyleChangedFromSettings, object: nil)
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
    
    /* Close pinnable window on click outside (aka. when window loses focus) */
    func windowDidResignKey(_ notification: Notification) {
        if(isPinned) { return }
        if(getWindowStyleFromAppStorage() == .windowed) {return}
        print("Window resigned key")
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
    
    /* Remember window size for next window */
    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            saveWindowSize(window.frame.size)
        }
    }
    
    func saveWindowSize(_ size: CGSize) {
        let sizeString = NSStringFromSize(size)
        UserDefaults.standard.set(sizeString, forKey: AppStorageKey.windowSizePref)
    }
    
    func pinWindow() -> Void {
        self.isPinned = true
    }
    
    func applyPinnableWindowStyle() -> Void {
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
    
    /* Notification Handlers */
    @objc func handleWindowClose() -> Void {
        if(self.isKeyWindow) {
            self.close()
        }
    }
    
    @objc func handleAppearanceChange() -> Void {
        let appearance = getAppearanceFromAppStorage()
        self.appearance = appearance
    }
    
    @objc func handleWindowStyleChange() -> Void {
        let windowStyle = getWindowStyleFromAppStorage()
        switch windowStyle {
        case .pinnable:
            applyPinnableWindowStyle()
        case .windowed:
            applyWindowedWindowStyle()
        }
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
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.isReleasedWhenClosed = false
        self.titleVisibility = .hidden
        self.hasShadow = false
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
func setupAppWindow(_ window: NSWindow) -> Void {
    // prevent conflict with the app window's resize event which would prevent the window from becoming key
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        window.center()
        window.makeKeyAndOrderFront(nil)
//        setWindowFrameOriginToCurrentScreen(window: window)
        setWindowFrameOriginToMousePosition(window: window)
    }
}

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
    let contentView = ContentView(window: window, url: url)
        .frame(minWidth: 500)
        .frame(minHeight: 300, maxHeight: 2000)
    window.appearance = getAppearanceFromAppStorage()
    window.contentView = NSHostingView(rootView: contentView)
    setupAppWindow(window)
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
    let contentView = LoadingView().frame(width: 200, height: 120)
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

func createPatchErrorWindow(string: String, description: String) -> Void {
    let window = NotificationWindow(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), backing: .buffered, defer: false)
    let contentView = PatchErrorView(window: window, string: string, description: description)
    window.contentView = NSHostingView(rootView: contentView)
    setupWindow(window)
}

/* Misc */
func getAppearanceFromAppStorage() -> NSAppearance {
    let rawValue = UserDefaults.standard.string(forKey: AppStorageKey.appearancePref) ?? AppearancePreference.system.rawValue
    let value = AppearancePreference(rawValue: rawValue)!
    return getPreferredAppearance(pref: value)
}

func getWindowStyleFromAppStorage() -> WindowStylePreference {
    let rawValue = UserDefaults.standard.string(forKey: AppStorageKey.windowStylePref) ?? DEFAULT_WINDOW_STYLE_PREFERENCE.rawValue
    let value = WindowStylePreference(rawValue: rawValue)!
    return value
}
