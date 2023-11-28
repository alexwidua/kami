//
// OpenAI+StreamCompletion.swift
//
// Author: Nate Parrott (2023
// Url: https://github.com/nate-parrott/openai-streaming-completions-swift/tree/main

import Foundation

extension OpenAI {

    public enum ChatCompletionStreamResult {
        case completion(Message)
        case error(String)
    }
    
    public  enum ChatCompletionError: Error {
        case noChoices
        case invalidResponse(ChatCompletionInvalidResponse)
        case noApiKey
    }
    
    public enum ChatCompletionErrorCode: Int {
        // https://platform.openai.com/docs/guides/error-codes
        case invalidAuth = 401
        case exceededQuota = 429
        case serverError = 500
        case engineOverloaded = 503
        var errorMessage: String {
            switch self {
            case .invalidAuth:
                return "Couldn't authenticte API Key or Organization ID. Did you set the correct Organization ID?" // Because we validate the API key in other places, we can assume that the user has set a wrong organization ID or that the problem is adjacent to that –– TODO: Validate Org ID in Settings
            case .exceededQuota:
                return "You exceeded your current OpenAI quota, please check your OpenAI plan and billing details."
            case .serverError:
                return "The OpenAI server had an error while processing your request."
            case .engineOverloaded:
                return "The OpenAI engine is currently overloaded, please try again later."
            }
        }
    }
    
    public struct ChatCompletionInvalidResponse: Codable {
        let error: ChatCompletionInvalidResponseDetail
    }
    
    public struct ChatCompletionInvalidResponseDetail: Codable {
        let message: String
        let type: String
        let code: String
        
    }
    
    public struct Message: Equatable, Codable, Hashable {
        public enum Role: String, Equatable, Codable, Hashable {
            case system
            case user
            case assistant
        }
        
        public var role: Role
        public var content: String
        
        public init(role: Role, content: String) {
            self.role = role
            self.content = content
        }
    }
    
    public struct ChatCompletionRequest: Codable {
        var messages: [Message]
        var model: String
        var max_tokens: Int = 1500
        var temperature: Double = 0.2
        var stream = false
        var stop: [String]?
        
        public init(messages: [Message], model: String = "gpt-3.5-turbo", max_tokens: Int = 1500, temperature: Double = 0.2, stop: [String]? = nil) {
            self.messages = messages
            self.model = model
            self.max_tokens = max_tokens
            self.temperature = temperature
            self.stop = stop
        }
    }
    
    // MARK: - Plain completion
    
    struct ChatCompletionResponse: Codable {
        struct Choice: Codable {
            var message: Message
        }
        var choices: [Choice]
    }
    
    public func completeChat(_ completionRequest: ChatCompletionRequest) async throws -> String {
        let request = try createChatRequest(completionRequest: completionRequest)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let decodedResponse = try JSONDecoder().decode(ChatCompletionInvalidResponse.self, from: data)
            throw ChatCompletionError.invalidResponse(decodedResponse)
        }
        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard completionResponse.choices.count > 0 else {
            throw ChatCompletionError.noChoices
        }
        return completionResponse.choices[0].message.content
    }
    
    // MARK: - Streaming completion
    
    public func completeChatStreaming(_ completionRequest: ChatCompletionRequest) throws -> AsyncStream<ChatCompletionStreamResult> {
        var _completionRequest = completionRequest
        _completionRequest.stream = true
        let request = try createChatRequest(completionRequest: _completionRequest)
        
        return AsyncStream { continuation in
            let evtSource = EventSource(urlRequest: request)
            var message = Message(role: .assistant, content: "")
            evtSource.onComplete { statusCode, reconnect, error in
                if let statusCode = statusCode, statusCode != 200 {
                    var errorMessage = "Unknown Error occurred."
                    if let errorCode = ChatCompletionErrorCode(rawValue: statusCode) {
                        errorMessage = errorCode.errorMessage
                        }
                    continuation.yield(.error(errorMessage))
                }
                continuation.finish()
            }
            evtSource.onMessage { id, event, data in
                guard let data, data != "[DONE]" else { return }
                do {
                    let decoded = try JSONDecoder().decode(ChatCompletionStreamingResponse.self, from: Data(data.utf8))
                    if let delta = decoded.choices.first?.delta {
                        message.role = delta.role ?? message.role
                        message.content = delta.content ?? ""
                        continuation.yield(.completion(message))
                    }
                } catch {
                    print("Chat completion error: \(error)")
                }
            }
            evtSource.connect()
        }
    }
    
    private struct ChatCompletionStreamingResponse: Codable {
        struct Choice: Codable {
            struct MessageDelta: Codable {
                var role: Message.Role?
                var content: String?
            }
            var delta: MessageDelta
        }
        var choices: [Choice]
    }
    
    private func decodeChatStreamingResponse(jsonStr: String) -> String? {
        guard let json = try? JSONDecoder().decode(ChatCompletionStreamingResponse.self, from: Data(jsonStr.utf8)) else {
            return nil
        }
        return json.choices.first?.delta.content
    }
    
    private func createChatRequest(completionRequest: ChatCompletionRequest) throws -> URLRequest {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let orgId {
            request.setValue(orgId, forHTTPHeaderField: "OpenAI-Organization")
        }
        request.httpBody = try JSONEncoder().encode(completionRequest)
        return request
    }
}

public class StreamingCompletion: ObservableObject {
    public enum Status: Equatable {
        case loading
        case complete
        case error
    }
    @Published public var status = Status.loading
    @Published public var text: String = ""
    
    init() {}
}

