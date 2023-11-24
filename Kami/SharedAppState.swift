//
// Shared App State
//

import SwiftUI

enum AppearancePreference: String, CaseIterable {
    case light
    case dark
    case system
}

/* @AppStoprage Keys */
let hasCompletedOnboardingStorageKey = "completed-onboarding-\(APP_VERSION)"
let showTrayIconWithPreferenceStorageKey = "show-tray-icon-\(APP_VERSION)"
let appearancePreferenceStorageKey = "appearance-\(APP_VERSION)"
let apiKeyStorageKey = "api-secret-key-\(APP_VERSION)"
let modelPreferenceStorageKey = "model-preference-\(APP_VERSION)"
let customModelPreferenceStorageKey = "custom-model-string-\(APP_VERSION)"
let instructionStorageKey = "model-instruction-text-\(APP_VERSION)"
let showOpenWithPreferenceStorageKey = "show-open-with-button-\(APP_VERSION)"
let showFileNamePreferenceStorageKey = "show-file-name-\(APP_VERSION)"

/* Running App State */
class AppState: ObservableObject {
    static let shared = AppState()
    @Published var windowReferences: [URL: NSWindow] = [:] // Dictionary to store window references
    
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

