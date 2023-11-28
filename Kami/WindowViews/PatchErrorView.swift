//
// PatchErrorView.swift
//
import SwiftUI

struct PatchErrorView: View {
    var window: NotificationWindow?
    var string: String
    var description: String
    
    var body: some View {
        VStack(spacing: 8.0) {
            HStack(spacing: 16.0) {
                Image("NotificationIconPatchError")
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("Couldn't open JavaScript Patch.")
                        .bold()
                    Text(description)
                }
            }
            HStack {
                Text(string)
                    .monospaced()
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.25))
                Spacer()
                Button("Dismiss") {
                    if let window = window {
                        window.close()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 16.0)
        .padding(.bottom, 14.0)
        .fixedSize(horizontal: true, vertical: true)
        .navigationTitle("Open Patch Error")
    }
}

#Preview {
    PatchErrorView(window: nil, string: "INVALID_PATCH_TYPE", description: "Oopsie")
}
