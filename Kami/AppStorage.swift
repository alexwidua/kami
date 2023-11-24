import SwiftUI

struct AppStorageKey {
    static let finishedOnboarding = "completed-onboarding-\(APP_VERSION)"
    static let apiKey = "api-secret-key-\(APP_VERSION)"
    static let modelPreference = "model-preference-\(APP_VERSION)"
    static let customModelString = "custom-model-string-\(APP_VERSION)"
    static let instructionText = "model-instruction-text-\(APP_VERSION)"
    static let appearancePref = "appearance-\(APP_VERSION)"
    static let windowStylePref = "window-preference-\(APP_VERSION)"
    static let showOpenWithBtnPref = "show-open-with-button-\(APP_VERSION)"
    static let showFileName = "show-file-name-\(APP_VERSION)"
}



