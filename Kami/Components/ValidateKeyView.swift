//
// ValidateKeyView.swift
//
import SwiftUI

#Preview {
    ValidateApiKeyView(apiKey: .constant("abc-123"), validationState: .constant(.pending), errorMessage: .constant(""), canDismiss: false, hasDismissed: .constant(false))
}

enum ValidationState {
    case pending
    case validating
    case invalid
    case valid
}

let API_KEY_INPUT_HEIGHT: CGFloat = 34
let API_KEY_FONT_SIZE: CGFloat = 12

struct ValidateApiKeyView: View {
    @Binding var apiKey: String
    @Binding var validationState: ValidationState
    @Binding var errorMessage: String
    var canDismiss: Bool
    @Binding var hasDismissed: Bool // user has interacted with 'Done' key after validation
    
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
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            TextField(placeholder, text: $tempApiKey)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                .font(.system(size: API_KEY_FONT_SIZE, design: .monospaced))
                .frame(height: API_KEY_INPUT_HEIGHT)
                .onSubmit {
                    validateApiKey(key: tempApiKey)
                }
            
            /* Validate Button */
            if(tempApiKey.isEmpty && validationState != .valid) {
                Spacer().frame(width: 1, height: API_KEY_INPUT_HEIGHT)
                // display invisible rect with same height as button to avoid layout shifts
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
                    .buttonStyle(CustomButtonStyle(buttonType: validationButtonType))
                }
                .padding(.horizontal, 8.0)
            }
        }
        .padding(0.0)
    }
    
    func validateApiKey(key: String) {
        validationState = .validating
        let api = OpenAI(apiKey: key)
        let messages: [OpenAI.Message] = [
            .init(role: .system, content: "Test"),
        ]
        
        Task {
            do {
                let _ = try await api.completeChat(.init(messages: messages, model: "gpt-3.5-turbo"))
                print("Valid API Key")
                validationState = .valid
                apiKey = tempApiKey
                tempApiKey = ""
                // remove focus from TextEditor
                DispatchQueue.main.async {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            } catch let error as OpenAI.ChatCompletionError {
                switch error {
                case .invalidResponse(let apiResponse as OpenAI.ChatCompletionInvalidResponse):
                    print("Error: \(apiResponse)")
                    errorMessage = apiResponse.error.message
                default:
                    print("Error: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
                validationState = .invalid
            } catch {
                print("Error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                validationState = .invalid
            }
        }
    }
}
