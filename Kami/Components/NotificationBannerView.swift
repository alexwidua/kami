//
// Dismissable Banner notification used to surface error states/warnings
// from the API endpoint to the app's main window
//
// TODO: Invalidate the timer when the window disappears. Otherwise, it can happen that consecutive notifications disappear immediately because they are attached to the previous timer.

import SwiftUI

#Preview {
    NotificationBannerView(isShowing: .constant(true), message: "Preview Message", notifStyle: .warning)
}

enum NotificationStyle {
    case regular
    case warning
}

struct NotificationBannerView: View {
    @Binding var isShowing: Bool
    var message: String
    var notifStyle: NotificationStyle = .regular
    var dismissAfter: TimeInterval = 10
    
    var notifStyleBgColor: Color {
        switch notifStyle {
        case .regular:
            return .blue
        case .warning:
            return .yellow
        }
    }
    
    var notifStyleFgColor: Color {
        switch notifStyle {
        case .regular:
            return .white
        case .warning:
            return .black
        }
    }
    
    var body: some View {
        if isShowing {
            HStack {
                Text(message)
                    .font(.system(size: 12))
                Spacer()
                Button(action: {
                    isShowing = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(notifStyleFgColor)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 6.0)
            .padding(.horizontal, 8.0)
            .background(notifStyleBgColor)
            .foregroundColor(notifStyleFgColor)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter) {
                    isShowing = false
                }
            }
        }
    }
}

