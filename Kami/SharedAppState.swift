//
// The app's state, consisting of
// • Persistent AppStorage store
// • 'Transient' local state that manages the current file or other UI states...
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
    @Published var filePathString: String = ""
    @Published var fileContent: String = ""
    @Published var isSavingFile: Bool = false
    @Published var hasSavedFile: Bool = false
    @Published var isParsingPasteboardFile: Bool = false
}

