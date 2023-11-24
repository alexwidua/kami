//
//  SplashView.swift
//  Kami
//
//  Created by Alex Widua on 24.11.23.
//

import SwiftUI
import KeyboardShortcuts

struct SplashView: View {
    @AppStorage(apiKeyStorageKey) var appStorage_apiKey: String = ""
    @State var appStorage_finishedOnboarding: Bool = true
    
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
                    Text("Open a selected JavaScript patch via the Right Click > Open with... context menu or the \(shortcutName) shortcut.")
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
            .padding()
            .navigationTitle(APP_NAME)
        }
       
    }
}

#Preview {
    SplashView()
}
