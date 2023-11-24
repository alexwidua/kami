import SwiftUI

enum ButtonType {
    case regular
    case primary
    case success
}

struct CustomButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    
    var buttonType: ButtonType = .regular
    var py: CGFloat = 4.0
    var px: CGFloat = 8.0
    
    var isLight: Bool {
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
            return isEnabled ? .white : .primary
        }
    }
    
    var getBtnBgColor: Color {
        switch buttonType {
        case .regular:
            return isLight ?
                .white : (isEnabled ? .white.opacity(0.25) : .white.opacity(0.25))
        case .primary, .success:
            return isLight ?
            (isEnabled ? specialColor : .white) :
            (isEnabled ? specialColor : .white.opacity(0.25))
        }
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(getBtnFgColor)
            .padding(.vertical, py)
            .padding(.horizontal, px)
            .background(RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(
                    getBtnBgColor
                        .shadow(
                            .inner(color: .white.opacity(0.25), radius: 0, x: 0, y: 1)
                        )
                        .shadow(
                            .drop(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
                        )
                )
            )
            .opacity(isEnabled ? 1 : 0.35)
    }
}
