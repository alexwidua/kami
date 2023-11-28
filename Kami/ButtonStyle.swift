//
// ButtonStyle.swift
//
import SwiftUI

enum ButtonType {
    case regular
    case primary
    case success
}

struct CustomButtonStyle: ButtonStyle {
    @Environment(\.controlActiveState) var controlActiveState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    
    var buttonType: ButtonType = .regular
    var py: CGFloat = 4.0
    var px: CGFloat = 8.0
    @State var parentIsKey: Bool = false
    
    var isLightTheme: Bool {
        return colorScheme == .light
    }
    
    var specialColor: Color {
        switch buttonType {
        case .regular:
            return .clear // never returns
        case .primary:
            return .blue
        case .success:
            return .green
        }
    }
    
    var getBtnFgColor: Color {
        switch buttonType {
        case .regular:
            return .primary
        case .primary, .success:
            return isEnabled && parentIsKey ? .white : .primary
        }
    }
    
    var getBtnBgActiveColor: Color {
        switch buttonType {
            case .regular:
                return isLightTheme ? .white : .white.opacity(0.25)
            case .primary, .success:
                return specialColor
        }
    }
    
    var getBtnBgDisabledColor: Color {
        switch buttonType {
            case .regular:
                return isLightTheme ? .white : .white.opacity(0.25)
            case .primary, .success:
                return isLightTheme ? .white : .white.opacity(0.25)
        }
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(getBtnFgColor)
            .padding(.vertical, py)
            .padding(.horizontal, px)
            .background(RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(
                    (isEnabled && parentIsKey ? getBtnBgActiveColor : getBtnBgDisabledColor)
                        .shadow(
                            .inner(color: .white.opacity(0.25), radius: 0, x: 0, y: 1)
                        )
                        .shadow(
                            .drop(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
                        )
                )
            )
            .opacity(isEnabled ? 1 : 0.35)
            .onChange(of: controlActiveState) { _, newValue in
                if (newValue == .key || newValue == .active) {
                    parentIsKey = true
                }
                else {
                    parentIsKey = false
                }
            }
    }
}
