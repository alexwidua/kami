//
// OpenAI.swift
//
// Author: Nate Parrott (2023
// Url: https://github.com/nate-parrott/openai-streaming-completions-swift/tree/main

import Foundation

public struct OpenAI {
    var apiKey: String
    var orgId: String?

    public init(apiKey: String, orgId: String? = nil) {
        self.apiKey = apiKey
        self.orgId = orgId
    }
}



