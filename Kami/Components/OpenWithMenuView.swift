//
// [Open with...] component that shows a dropdown menu with all installed applications
// that announce themselves as JavaScript editor.
//

import SwiftUI
import CoreServices

struct OpenWithMenuView: View {
    @StateObject var appState = AppState.shared
    
    var url: URL
    var window: AppWindow

    var body: some View {
        Menu {
            ForEach(getAppsThatCanEditJsFiles(url: url), id: \.self) { appURL in
                Button(action: {
                    openFileInSelectedApp(appURL: appURL)
                }) {
                    Image(nsImage: getAppIcon(for: appURL))
                    Text(getAppName(appURL: appURL))
                }
            }
        } label: {
            Text("Open with...")
        }
        .menuIndicator(.hidden)
    }
    
    // Returns all apps that announce themselves as .js editors
    func getAppsThatCanEditJsFiles(url: URL) -> [URL] {
        let getAllEditors = LSCopyApplicationURLsForURL(url as CFURL, .editor)?.takeRetainedValue() as? [URL] ?? []
        // get the this app's bundle identifier and filter it from the list
        let currentAppBundleIdentifier = Bundle.main.bundleIdentifier
        return getAllEditors.filter { appURL in
            let appBundle = Bundle(url: appURL)
            return appBundle?.bundleIdentifier != currentAppBundleIdentifier
        }
    }
    
    func getAppIcon(for appURL: URL) -> NSImage {
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
    
    func getAppName(appURL: URL) -> String {
        let bundle = Bundle(url: appURL)
        return bundle?.localizedInfoDictionary?["CFBundleDisplayName"] as? String ?? bundle?.infoDictionary?["CFBundleDisplayName"] as? String ?? "Unknown App"
    }
    
    func openFileInSelectedApp(appURL: URL) {
        guard url.isFileURL else { return }
        
        // 1. Save current file content
        var fileContent = ""
        do {
            fileContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("*** [OpenWithView] Error reading file: \(error)")
           return
        }
        
        do {
            try fileContent.write(to: url, atomically: true, encoding: .utf8)
            print("*** [OpenWithView] File saved successfully")
        } catch {
            print("*** [OpenWithView] Error saving file: \(error)")
        }
        
        // 2. Open file in selected app
        if appURL.startAccessingSecurityScopedResource() {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { (response, error) in
                if let error = error {
                    print("*** [OpenWithView] Error opening file: \(error.localizedDescription)")
                }
            }
            appURL.stopAccessingSecurityScopedResource()
        }
        
        // 3. Close window
        appState.removeWindowReference(for: url)
        window.close()
    }
    
}
