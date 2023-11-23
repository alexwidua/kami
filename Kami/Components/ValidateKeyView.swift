//
// API Key Validation Component that is shown during the onboarding flow and in the settings window.
// The validation works by sending a test API request to the OpenAI endpoint using the cheapest model (as of Nov 2023).
//

import SwiftUI
import OpenAI

#Preview {
    ValidateApiKeyView(apiKey: .constant("abc-123"), validationState: .constant(.pending), errorMessage: .constant(""), canDismiss: false, hasDismissed: .constant(false))
}

enum ValidationState {
    case pending
    case validating
    case invalid
    case valid
}

enum ValidationInputStyle {
    case compact
    case onboarding
}

struct ValidateApiKeyView: View {
    
    /* Props */
    @Binding var apiKey: String
    @Binding var validationState: ValidationState
    @Binding var errorMessage: String
    var canDismiss: Bool
    @Binding var hasDismissed: Bool // user has interacted with 'Done' key after validation
    var validationInputStyle: ValidationInputStyle = .compact
    
    /* States */
    @State private var tempApiKey = ""
    
    /* Computed */
    var placeholder: String {
        if(apiKey.isEmpty) {
            return "Enter API Secret Key..."
        }
        // "Abcdefg-12345" -> "Abc...2345"
        else {
            let prefix = apiKey.prefix(3)
            let suffix = apiKey.suffix(4)
            return "\(prefix)...\(suffix)"
        }
    }
    
    private var validateButtonDisabled: Bool {
        return validationState == .validating || (!canDismiss && validationState == .valid)
    }
    
    private var isValidating: Bool {
        return validationState == .validating
    }
    
    /* Constants */
    var inputHeight: CGFloat = 34
    
    /* Functions */
    func validateApiKey(key: String) {
        validationState = .validating
        let openAI = OpenAI(apiToken: key)
        let query = ChatQuery(model: .gpt3_5Turbo, messages: [
            .init(role: .system, content: "Test."),
        ])
        openAI.chats(query: query) { result in
            switch result {
            case .success:
                print("Success")
                validationState = .valid
                apiKey = tempApiKey
                tempApiKey = ""
                // remove focus from TextEditor
                DispatchQueue.main.async {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
                
            case .failure(let error):
                print("Error: \(error)")
                errorMessage = error.localizedDescription
                validationState = .invalid
            }
        }
    }
    
    /* Computed props */
    var validationButtonType: ButtonType {
        switch validationState {
        case .pending,  .invalid:
            return .primary
        case .validating:
            return .regular
        case .valid:
            return canDismiss ? .primary : .success
        }
    }
    
    var fontSize: CGFloat {
        switch validationInputStyle {
        case .compact:
            return 12.0
        case .onboarding:
            return 14.0
        }
    }

    var buttonPaddingY: CGFloat {
        switch validationInputStyle {
        case .compact:
            return 2.0
        case .onboarding:
            return 4.0
        }
    }
    
    var buttonPaddingX: CGFloat {
        switch validationInputStyle {
        case .compact:
            return 4.0
        case .onboarding:
            return 8.0
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ZStack {
                TextField("", text: .constant(placeholder))
                    .textFieldStyle(PlainTextFieldStyle())
                
                    .allowsHitTesting(false)
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                    .font(.system(size: fontSize, design: .monospaced))
                    .opacity(tempApiKey.isEmpty ? 1 : 0)
                    .frame(height: inputHeight)
                TextField("", text: $tempApiKey)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                    .font(.system(size: fontSize, design: .monospaced))
                    .frame(height: inputHeight)
                    .onSubmit {
                        validateApiKey(key: tempApiKey)
                              }

            }
            
            /* Validate Button */
            // Display invisible rect with same height as button to avoid layout shifts
            if(tempApiKey.isEmpty && validationState != .valid) {
                Spacer().frame(width: 1, height: inputHeight)
            }
            else {
                ZStack {
                    Button(action: {
                        if(validationState == .valid) {
                            hasDismissed = true
                        }
                        else {
                            validateApiKey(key: tempApiKey)
                        }
                    }) {
                        HStack(alignment: .center, spacing: 4.0 ) {
                            // Icon
                            switch validationState {
                            case .pending:
                                Image(systemName: "return")
                            case .validating:
                                ProgressView()
                                    .controlSize(.small)
                                Spacer().frame(width:8)
                            case .invalid:
                                Image(systemName: "return")
                            case .valid:
                                EmptyView()
                            }
                            // Text
                            switch validationState {
                            case .pending:
                                Text("Validate")
                            case .validating:
                                Text("Validating...")
                            case .invalid:
                                Text("Validate")
                            case .valid:
                                Text(canDismiss ? "Done" : "Saved")
                            }
                            
                        }
                    }
                    .disabled(validateButtonDisabled)
                    .buttonStyle(CustomButtonStyle(buttonType: validationButtonType, py: buttonPaddingY, px: buttonPaddingX))
                }
                .padding(.horizontal, 8.0)
            }
        }
        .padding(0.0)
    }
}

