import SwiftUI

struct AppStorageKey {
    static let finishedOnboarding = "completed-onboarding-\(STORAGE_KEY_SUFFIX)"
    static let apiKey = "api-secret-key-\(STORAGE_KEY_SUFFIX)"
    static let modelPreference = "model-preference-\(STORAGE_KEY_SUFFIX)"
    static let customModelString = "custom-model-string-\(STORAGE_KEY_SUFFIX)"
    static let instructionText = "model-instruction-text-\(STORAGE_KEY_SUFFIX)"
    static let appearancePref = "appearance-\(STORAGE_KEY_SUFFIX)"
    static let windowStylePref = "window-preference-\(STORAGE_KEY_SUFFIX)"
    static let showOpenWithBtnPref = "show-open-with-button-\(STORAGE_KEY_SUFFIX)"
    static let showFileNamePref = "show-file-name-\(STORAGE_KEY_SUFFIX)"
}



