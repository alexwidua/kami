//
// API Fetch stuff...
//
// Note: We already strip Javascript Markdown syntax from the response here.
// While it'd be more elegant to prompt GPT to not include Markdown, I found this way to be more successfull...
//

import Foundation
import SwiftUI
import OpenAI

enum StreamResult {
    case completion(StreamCompletion)
    case error(StreamError)
}

struct StreamCompletion {
    var tokenIndex: Int
    var token: String
}

struct StreamError {
    var message: String
}

/* Stream completion, token by token */
func streamCompletion(task: Binding<Task<Void, Never>?>, apiKey: String?, instructionText: String?, inputText: String?, model: String?) -> AsyncStream<StreamResult> {
    
    return AsyncStream<StreamResult> { continuation in
        
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            let apiKeyError = "No or incorrect API key provided: \(apiKey ?? "(empty)"). You can find your API key at https://platform.openai.com/account/api-keys."
            print("*** [StreamCompletion] \(apiKeyError)")
            continuation.yield(StreamResult.error(StreamError(message: "\(apiKeyError)")))
            continuation.finish()
            return
        }
        
        guard let instructionText = instructionText, !instructionText.isEmpty else {
            let instructionTextError = "No instruction text provided. You can set the instruction text in the app's settings menu."
            print("*** [StreamCompletion] \(instructionTextError)")
            continuation.yield(StreamResult.error(StreamError(message: "\(instructionTextError)")))
            continuation.finish()
            return
        }
        
        guard let inputText = inputText, !inputText.isEmpty else {
            let inputTextError = "No prompt provided. Please enter a prompt."
            print("*** [StreamCompletion] \(inputTextError)")
            continuation.yield(StreamResult.error(StreamError(message: "\(inputTextError)")))
            continuation.finish()
            return
        }
        
        guard let model = model, !model.isEmpty else {
            let modelError = "No model provided. Please provide a model name."
            print("*** [StreamCompletion] \(modelError)")
            continuation.yield(StreamResult.error(StreamError(message: "\(modelError)")))
            continuation.finish()
            return
        }
        
        let openAI = OpenAI(apiToken: apiKey)
        let query = ChatQuery(model: model, messages: [
            .init(role: .system, content: instructionText),
            .init(role: .user, content: inputText)
        ])
        
        print("*** [StreamCompletion] Initiated completion stream with prompt: \(inputText), using model: \(model).")
        
        task.wrappedValue = Task {
            var previousToken = ""
            var tokenIndex = 0
            do {
                for try await result in openAI.chatsStream(query: query) {
                    if let firstChoice = result.choices.first, let token = firstChoice.delta.content {

                        let filteredToken = filterJsMarkdownFromToken(currentToken: token, previousToken: previousToken)
                        let completion = StreamCompletion(tokenIndex: tokenIndex, token: filteredToken)
                        continuation.yield(StreamResult.completion(completion))
                        
                        previousToken = token
                        tokenIndex += 1
                    }
                }
            } catch {
                let queryError = error.localizedDescription
                print("Query Error: \(queryError)")
                continuation.yield(StreamResult.error(StreamError(message: "\(queryError)")))
            }
            continuation.finish()
            print("*** [StreamCompletion] Finished streaming completion.")
        }
    }
}

/* (Naive way) of filtering out the code block Markdown syntax from the GPT response. Found to be more reliabe than just prompting */
func filterJsMarkdownFromToken(currentToken: String, previousToken: String) -> String {
    let backticks = "```"
    let keyword = "javascript"
    
    if (currentToken == backticks || currentToken == keyword && previousToken == backticks || currentToken == "\(backticks)\(keyword)") {
        return ""
    }
    
    return currentToken
}

