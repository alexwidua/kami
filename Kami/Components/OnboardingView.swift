//
// OnboardingView.swift
//
import SwiftUI

struct OnboardingView: View {
    @Binding var apiKey: String
    @Binding var finishedOnboarding: Bool
    
    @State private var onboardingValidationState: ValidationState = .pending
    @State private var onboardingErrorMessage: String = ""
    @State private var onboardingHasInteractedWithDismissButton: Bool = false
    
    var onboardingSubtitleText: AttributedString {
        let urlWithoutHttps = "platform.openai.com/account/api-keys"
        var result = AttributedString("Enter your OpenAI API Key. You can find your API key at \(urlWithoutHttps).\nYour API key is only stored locally on your machine.")
        let linkRange = result.range(of: urlWithoutHttps)!
        result[linkRange].link = URL(string: "https://\(urlWithoutHttps)")
        result[linkRange].underlineStyle = Text.LineStyle(pattern: .solid)
        result[linkRange].foregroundColor = .white
        return result
    }
    
    private var onboardingBackground: Color {
        switch onboardingValidationState {
        case .pending:
            return .blue
        case .validating:
            return .blue
        case .invalid:
            return .red
        case .valid:
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing:0) {
            ZStack {
                ValidateApiKeyView(apiKey: $apiKey, validationState:  $onboardingValidationState, errorMessage: $onboardingErrorMessage, canDismiss: true, hasDismissed: $onboardingHasInteractedWithDismissButton)
                    .onChange(of: onboardingHasInteractedWithDismissButton) { _, hasDismissed in
                        if(hasDismissed) {
                            finishedOnboarding = true
                        }
                    }
            }
            .padding(0.0)
            ZStack {
                switch onboardingValidationState {
                case .pending, .validating:
                    HStack {
                        Text(onboardingSubtitleText)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                case .invalid:
                    HStack {
                        Text(onboardingErrorMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                case .valid:
                    HStack {
                        Text("Your API Key has been saved. You can change it in the settings anytime.")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
            .padding([.leading, .bottom, .trailing], 8.0)
            
        }
        .padding(0.0)
        .background(onboardingBackground)
    }
}

#Preview {
    OnboardingView(apiKey: .constant("abc-123"), finishedOnboarding: .constant(false))
}
