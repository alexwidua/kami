
import SwiftUI

struct PatchErrorView: View {
    var window: NotificationWindow?
    var message: String
    
    var body: some View {
        VStack(spacing: 8.0) {
            HStack(spacing: 16.0) {
                Image("NotificationIconPatchError")
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("Couldn't open JavaScript Patch.")
                        .bold()
                    Text(message)
                }
            }
            HStack {
                Spacer()
                Button("Dismiss") {
                    if let window = window {
                        window.close()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .fixedSize(horizontal: true, vertical: true)
        .navigationTitle("Open Patch Error")
    }
}

#Preview {
    PatchErrorView(window: nil, message: "ERROR_MSG")
}
