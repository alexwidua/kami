// Custom Request Accessibility Permission dialog to show additional information why the permission is being requested (there is no native way to display a custom message)

import SwiftUI

struct AccessibilityRequestView: View {
    var window: NotificationWindow?
    var body: some View {
        VStack(spacing: 16.0) {
            HStack(spacing: 16.0) {
                Image("NotificationIconAXU")
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("\(APP_NAME) needs accessibility permissions to open a JavaScript patch via the shortcut.")
                        .bold()
                    Text("Grant access to this application in Privacy & Security settings, located in System Settings.")
                }
            }
            HStack {
                Spacer()
                Button("Open System Settings") {
                    if let window = window {
                        if let privacySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(privacySettingsURL)
                        }
                        window.close()
                    }
                }
                Button("Deny") {
                    if let window = window {
                        window.close()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 450)
        .navigationTitle("Accessibility Access")
    }
}

#Preview {
    AccessibilityRequestView(window: nil)
}
