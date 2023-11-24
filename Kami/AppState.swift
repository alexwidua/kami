import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var windowReferences: [URL: NSWindow] = [:] 
    
    func addWindowReference(for url: URL, window: NSWindow) {
        windowReferences[url] = window
    }
    func removeWindowReference(for url: URL) {
        windowReferences.removeValue(forKey: url)
    }
    func getWindowReference(for url: URL) -> NSWindow? {
        return windowReferences[url]
    }
}

