//
// NotificationBannerView.swift
//
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
    
    @State private var isPinned: Bool = false
    @State private var closeBtnPressed: Bool = false
    @State private var closeBtnHover: Bool = false
    
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
                Rectangle()
                    .fill(.primary.opacity(closeBtnHover ? 0.1 : 0.0))
                    .cornerRadius(6.0)
                    .overlay {
                        ZStack {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(notifStyleFgColor)
                        }
                    }
                    .scaleEffect(closeBtnPressed ? 0.9 : 1)
                    .animation(.spring(duration: 0.4, bounce: 0.25), value: isPinned)
                    .onHover(perform: { hovering in
                        closeBtnHover = hovering
                    })
                    .modifier(MouseEvt(
                        onMouseDown: {
                            closeBtnPressed = true
                        },
                        onMouseUp: {
                            closeBtnPressed = false
                            isShowing = false
                        }
                    ))
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, 6.0)
            .padding(.horizontal, 8.0)
            .background(notifStyleBgColor)
            .foregroundColor(notifStyleFgColor)
        }
    }
}

