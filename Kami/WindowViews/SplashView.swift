// Splash screen that gets shown on initial startup
// Shows either 'Enter API Key' prompt or a hint how to use the app...

import SwiftUI
import KeyboardShortcuts

struct SplashView: View {
    @AppStorage(AppStorageKey.apiKey) var appStorage_apiKey: String = ""
    @AppStorage(AppStorageKey.finishedOnboarding) var appStorage_finishedOnboarding: Bool = false

    var shortcutName: String {
        var string = ""
        if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleAppWindow) {
            string = shortcut.description
        }
        return string
    }
    
    var body: some View {
        if(!appStorage_finishedOnboarding) {
            OnboardingView(apiKey: $appStorage_apiKey, finishedOnboarding: $appStorage_finishedOnboarding)
                .navigationTitle("Enter your API Key")
        }
        else {
            HStack {
                ZStack{
                    Image("SplashIconPatch")
                    if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleAppWindow) {
                        Text(shortcut.description)
                            .padding(4.0)
                            .background(.white.opacity(0.2))
                            .background(.ultraThinMaterial)
                            .cornerRadius(6.0)
                            .offset(x: 34, y: 14)
                    }
                }
                VStack(alignment: .leading) {
                    Text("Open a JavaScript patch via the Right Click > Open with... context menu or the \(shortcutName) shortcut after selecting it.")
                        .bold()
                    HStack(spacing: 4.0) {
                        Text("You can configure the shortcut in the settings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Open Settings") {
                            let _ = createSettingsWindow()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                        .font(.subheadline)
                    }
                }
                
            }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 14.0)
            .navigationTitle(APP_NAME)
        }
       
    }
}

#Preview {
    SplashView()
}
