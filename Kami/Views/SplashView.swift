//
// SplashView.swift
//
import SwiftUI
import KeyboardShortcuts

#Preview {
    SplashView()
}

struct SplashView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissWindow
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
            VStack(spacing: 12.0) {
                HStack(spacing: 0) {
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
                    .padding(.trailing, 24.0)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("There are two ways to open a JavaScript patch:")
                            .bold()
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "a.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.primary, .primary.opacity(0.1))
                                    .frame(width: 16, height: 16)
                                Text("Select a JavaScript Patch and use the shortcut **\(shortcutName)**")
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Image(systemName: "b.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.primary, .primary.opacity(0.1))
                                    .frame(width: 16, height: 16)
                                Text("Right-click a JavaScript Patch and choose **Open with...**")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.leading, 8.0)
                        HStack(spacing: 4.0) {
                            Text("You can configure the shortcut in the settings anytime.")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24.0)
                .background {
                    RoundedRectangle(cornerRadius: 8.0)
                        .fill(colorScheme == .light ? .white.opacity(0.25) : .white.opacity(0.05))
                        .stroke(.black.opacity(0.05), lineWidth: 1)
                }
                HStack(alignment: .bottom) {
                    Text("Kami is now running in the background.\nYou can quit the app anytime via the icon in the top menu bar.")
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                  Spacer()
                    Button("Open Settings") {
                        createSettingsWindow()
                    }
                    Button("Got it") {
                        dismissWindow()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16.0)
            .navigationTitle(APP_NAME)
        }
    }
}
