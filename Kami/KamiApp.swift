import SwiftUI
import KeyboardShortcuts



@main
struct KamiApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate : AppDelegate
    @StateObject var appState = AppState.shared
    
    var body: some Scene {
        Settings() {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @ObservedObject var appState = AppState.shared
    var statusBarItem: NSStatusItem!
    var keyUpEventMonitor: Any?
    
    var launchedBecauseOpenFile: Bool = false
    var isParsingPasteboardFile: Bool = false
    
    override init() {
        super.init()
        /* Observe app focus changes. We do this to check if Origami is the active app and either enable/disable the app's shortcuts. If we don't do this, the shortcuts are blocked across other apps. */
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleKeyAppChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        createStatusBarItem()
        
        // GLOBAL keyboard events. We make sure to only capture them when Origami Studio is in the foreground
        KeyboardShortcuts.onKeyUp(for: .toggleAppWindow) { [self] in
            print("*** Pasteboard keyboard shortcut fired")
            if(isParsingPasteboardFile) {
                print("Already parsing pasteboard, exiting...")
                return
            }
            isParsingPasteboardFile = true
            
            let hasRequiredPermission = checkIfUserHasGrantedAccessibilityPermission()
            if(!hasRequiredPermission) {
                createAccessibilityRequestWindow()
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            
            let loadingWindow = createLoadingWindow()
            
            Task {
                let origamiJavaScriptPatchHandler = OrigamiJavaScriptPatchHandler()
                let result = await origamiJavaScriptPatchHandler.tryToCopyOrigamiJavaScriptPatchAndReadFilePathFromPasteboard()
                switch result {
                case .success(let filePathString):
                    if let url = URL(string: filePathString) {
                        openAppWindow(with: url)
                        loadingWindow.close()
                        isParsingPasteboardFile = false
                    }
                
                case .failure(let error):
                    print("*** [OrigamiJavaScriptPatchHandler] Error: Failed with error: \(error)")
                    var errorString = ""
                    var errorDescription = ""
                 
                    switch error {
                    case .couldNotPostCommandCopyDownEvent:
                        errorString = "POST_COPY_ERR"
                        errorDescription = "Couldn't do copy action."
                    case .timeout, .invalidPatchType:
                        errorString = "INVALID_PATCH_TYPE"
                        errorDescription = "Did you select a JavaScript patch?"
                    case .couldNotConvertBinaryDataToPropertyList:
                        errorString = "BPLIST_ERR"
                        errorDescription = "Couldn't convert Pasteboard data."
                    case .couldNotFindPathPropertyInOrigamiPropertyList, .couldNotFindJavaScriptFileInsideFileDirectory:
                        errorString = "INVALID_FILE_PATH"
                        errorDescription = "Couldn't find associated JavaScript file."
                    }
                    createPatchErrorWindow(string: errorString, description: errorDescription)
                    NSApp.activate(ignoringOtherApps: true)
                    loadingWindow.close()
                    isParsingPasteboardFile = false
                }
            }
        }
        
        // Keyboard events that only trigger if the app window is key
        keyUpEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [self] event in
           
            if event.keyCode == 53 { // 53 === escape key
                let windowStyle = getWindowStyleFromAppStorage()
                if(windowStyle == .pinnable) {
                    NotificationCenter.default.post(name: .closeAppWindowFromShortcut, object: nil)
                    return nil
                }

            }
            
            if event.modifierFlags.contains(.command) && event.keyCode == 1 { // command + s
                NotificationCenter.default.post(name: .saveFileFromShortcut, object: nil)
                return nil
            }
            return event
        }
        
        /* If the user didn't finish onboarding, we always show the splash screen. Otherwise, we only show it if the app was launched NOT bc a file wants to be opened */
        var finishedOnboarding = UserDefaults.standard.bool(forKey: AppStorageKey.finishedOnboarding)
        if(UserDefaults.standard.object(forKey: AppStorageKey.finishedOnboarding) == nil ) {
            finishedOnboarding = false
        }
        if(!finishedOnboarding || !launchedBecauseOpenFile) {
            createSplashWindow()
        }
    }
    
    /* Handle files opened from Origami via the 'Open with...' ctx menu */
    func application(_ application: NSApplication, open urls: [URL]) {
        launchedBecauseOpenFile = true
        if let firstURL = urls.first {
            openAppWindow(with: firstURL)
        }
    }
    
    func createStatusBarItem() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "StatusbarIcon")
            button.action = #selector(handleStatusBarItemAction(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
   
        statusBarItem.isVisible = true
    }
    
    @objc func handleStatusBarItemAction(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            
            let settingsItem = NSMenuItem()
            settingsItem.title = "Settings..."
            settingsItem.action = #selector(openSettingsWindow)
            
            let quitItem = NSMenuItem()
            quitItem.title = "Quit"
            quitItem.action = #selector(terminateApp)
            
            let menu = NSMenu()
            menu.addItem(settingsItem)
            menu.addItem(.separator())
            menu.addItem(quitItem)
            
            button.menu = menu
            button.menu?.popUp(positioning: nil, at: CGPoint(x: 0, y: button.bounds.maxY + 8.0), in: button)
        }
    }

    func openAppWindow(with url: URL) -> Void {
        if let existingWindow = appState.getWindowReference(for: url) {
            existingWindow.makeKeyAndOrderFront(nil)
        } else {
            let window = createAppWindow(url: url)
            appState.addWindowReference(for: url, window: window)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openSettingsWindow(_ sender: AnyObject?) {
        createSettingsWindow()
        if let settingsWindow = settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    
    /* Disable global keyboard shortcuts if Origami isn't key */
    @objc func handleKeyAppChanged(notification: NSNotification) {
        if let info = notification.userInfo,
           let app = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           let id = app.bundleIdentifier {
            if(id == ORIGAMI_TARGET_BUNDLE_ID) {
                print("*** [handleKeyAppChanged] Key app is Origami Studio")
                KeyboardShortcuts.isEnabled = true
            }
            else {
                KeyboardShortcuts.isEnabled = false
            }
        }
    }
    
    @objc func terminateApp(_ sender: AnyObject?) {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let evtMonitor = keyUpEventMonitor {
            NSEvent.removeMonitor(evtMonitor)
        }
    }
}

