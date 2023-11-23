import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleAppWindow = Self("toggleAppWindow", default: .init(.j, modifiers: [.command]))
}

extension Notification.Name {
    static let openAppWindow = Notification.Name("openMainWindowNotification")
    static let toggleTrayIcon = Notification.Name("toggleTrayIconNotification")
    static let bannerNotification = Notification.Name("bannerNotification")
}

@main
struct JavascriptEditorApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate : AppDelegate
    @StateObject var appState = AppState.shared
    
    var body: some Scene {
        Settings() {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private let targetBundleID = ORIGAMI_TARGET_BUNDLE_ID
    @ObservedObject var appState = AppState.shared
    var statusBarItem: NSStatusItem!
    var window: AppWindow!
    
    var keyUpEventMonitor: Any?
    var hasFinishedLaunching = false
    
    override init() {
        super.init()
        /* Observe app-window-open events called from other classes/views */
        NotificationCenter.default.addObserver(self, selector: #selector(handleOpenAppWindow), name: .openAppWindow, object: nil)
        /* Used by Settings Window */
        NotificationCenter.default.addObserver(self, selector: #selector(handleTrayIconVisibility), name: .toggleTrayIcon, object: nil)
        /* Observe app focus changes. We do this to check if Origami is the active app and either enable/disable the app's shortcuts. If we don't do this, the shortcuts are blocked across other apps. */
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleKeyAppChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = setupAppWindow()
        self.window = window
        
        setupStatusBarItem()
        
        // GLOBAL keyboard events. We make sure to only capture them when Origami Studio is in the foreground
        KeyboardShortcuts.onKeyUp(for: .toggleAppWindow) { [self] in
            openAppWindow(sender: nil, activate: false)
    
            let hasRequiredPermission = checkIfUserHasGrantedAccessibilityPermission()
            if(!hasRequiredPermission) {
                NotificationCenter.default.post(name: .bannerNotification, object: nil, userInfo: ["msg": "Accessibility permission is required to open JavaScript Patches via the Shortcut."])
                return
            }
            appState.isParsingPasteboardFile = true
            Task {
                let origamiJavaScriptPatchHandler = OrigamiJavaScriptPatchHandler()
                let result = await origamiJavaScriptPatchHandler.tryToCopyOrigamiJavaScriptPatchAndReadFilePathFromPasteboard()
                switch result {
                case .success(let filePathString):
                    handleOpenFile(filePath: filePathString) { (canOpenFile) -> () in
                        if(canOpenFile) {
                            NSApp.activate(ignoringOtherApps: true)
                            appState.isParsingPasteboardFile = false
                        }
                    }
                case .failure(let error):
                    print("*** [OrigamiJavaScriptPatchHandler] Error: Failed with error: \(error)")
                    NotificationCenter.default.post(name: .bannerNotification, object: nil, userInfo: ["msg": "Couldn't open JavaScript Patch. Did you select a JavaScript Patch?"])
                    appState.isParsingPasteboardFile = false
                }
            }
        }
        
        
        // Keyboard events that only trigger if the app window is key
        keyUpEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [self] event in
            if event.keyCode == 53 { // 53 === escape key
                self.closeAppWindow(nil)
                return nil
            }
            
            if event.modifierFlags.contains(.command) && event.keyCode == 1 { // command + s
                saveFile(filePathString: self.$appState.filePathString, isSavingFile: self.$appState.isSavingFile, hasSavedFile: $appState.hasSavedFile, fileContent: self.$appState.fileContent)
                return nil
            }
            return event
        }
        
        openAppWindow(sender: nil)
        hasFinishedLaunching = true
    }
    
    /* Handle files opened from Origami via the 'Open with...' ctx menu */
    func application(_ application: NSApplication, open urls: [URL]) {
        if let firstURL = urls.first {
            let filePathString = firstURL.absoluteString
            handleOpenFile(filePath: filePathString) { (canOpenFile) -> () in
                if(canOpenFile) {
                    if(hasFinishedLaunching) {
                        openAppWindow(sender: nil)
                    }
                }
            }
        }
    }
    
    func setupStatusBarItem() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "StatusbarIcon")
            button.action = #selector(handleStatusBarItemAction(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        var showTrayIcon = UserDefaults.standard.bool(forKey: showTrayIconWithPreferenceStorageKey)
        // if user hasn't made any preference change, show icon by default
        if(UserDefaults.standard.object(forKey: showTrayIconWithPreferenceStorageKey) == nil ) {
            showTrayIcon = true
        }
        statusBarItem.isVisible = showTrayIcon
    }
    
    @objc func handleStatusBarItemAction(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            
            let openAppItem = NSMenuItem()
            openAppItem.title = "Open \(APP_NAME)"
            openAppItem.action = #selector(handleOpenAppWindow)
            
            let settingsItem = NSMenuItem()
            settingsItem.title = "Settings..."
            settingsItem.action = #selector(handleOpenSettingsWindow)
            
            let quitItem = NSMenuItem()
            quitItem.title = "Quit"
            quitItem.action = #selector(handleQuitApp)
            
            let menu = NSMenu()
            menu.addItem(openAppItem)
            menu.addItem(settingsItem)
            menu.addItem(.separator())
            menu.addItem(quitItem)
            
            button.menu = menu
            button.menu?.popUp(positioning: nil, at: CGPoint(x: 0, y: button.bounds.maxY + 8.0), in: button)
        }
    }
    
    func openAppWindow(sender: AnyObject?, activate: Bool = true) {
        setWindowFrameOriginToCurrentScreen(window: window)
        window.makeKeyAndOrderFront(sender)
        if(activate) {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func closeAppWindow(_ sender: AnyObject?) {
        window.orderOut(sender)
    }
    
    /* Handlers */
    func handleOpenFile(filePath: String, completion: (Bool)->()) -> Void {
        if let url = URL(string: filePath) {
            do {
                let fileContents = try String(contentsOf: url, encoding: .utf8)
                AppState.shared.fileContent = fileContents
                AppState.shared.filePathString = url.absoluteString
                completion(true)
            } catch {
                print("Error reading file contents: \(error)")
                completion(false)
                // TODO: This error should be reflected in the UI somehow
            }
            
        }
    }
    
    @objc func handleOpenAppWindow(_ sender: AnyObject?) {
        openAppWindow(sender: sender)
    }
    
    @objc func handleQuitApp(_ sender: AnyObject?) {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func handleTrayIconVisibility(_ notification: NSNotification) {
        if let visibility = notification.userInfo?["visibility"] as? Bool {
            if let item = statusBarItem {
                item.isVisible = visibility
            }
        }
    }
    
    @objc func handleOpenSettingsWindow(_ sender: AnyObject?) {
        let window = setupSettingsWindow(openAppWindowAfterClose: false)
        setWindowFrameOriginToCurrentScreen(window: window)
        window.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /* Disable global keyboard shortcuts if Origami isn't key */
    @objc func handleKeyAppChanged(notification: NSNotification) {
        if let info = notification.userInfo,
           let app = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           let id = app.bundleIdentifier {
            if(id == targetBundleID) {
                print("*** [handleKeyAppChanged] Key app is Origami Studio")
                KeyboardShortcuts.isEnabled = true
            }
            else {
                KeyboardShortcuts.isEnabled = false
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let evtMonitor = keyUpEventMonitor {
            NSEvent.removeMonitor(evtMonitor)
        }
    }
}

