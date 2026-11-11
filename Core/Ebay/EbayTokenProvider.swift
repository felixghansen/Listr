//
//  EbayTokenProvider.swift
//  Listr
//
//  Created by Felix on 10/30/26.
//

import Foundation
import FirebaseFunctions

protocol EbayTokenProvider: Sendable {
    func accessToken() async throws -> String
}

enum EbayTokenError: LocalizedError {
    case missingEnvironmentToken
    case notConnected
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .missingEnvironmentToken:
            return "No eBay token found. Set EBAY_SANDBOX_TOKEN in the Xcode scheme."
        case .notConnected:
            return "Your eBay account isn't connected. Connect it in Account Settings."
        case .unexpectedResponse:
            return "Couldn't get an eBay token. Please try again."
        }
    }
}

actor CloudFunctionTokenProvider: EbayTokenProvider {
    static let shared = CloudFunctionTokenProvider()
    
    private var cachedToken: String?
    private var expiresAt: Date?
    
    private let functions = Functions.functions()
    private let refreshMargin: TimeInterval = 60
    
    private var refreshTask: Task<String, Error>?
    
    func accessToken() async throws -> String {
        if let cachedToken, let expiresAt, Date().addingTimeInterval(refreshMargin) < expiresAt {
            return cachedToken
        }
        
        if let refreshTask {
            return try await refreshTask.value
        }
        
        let task = Task {
            try await fetchToken()
        }
        
        refreshTask = task
        defer { refreshTask = nil }
        
        return try await task.value
    }
    
    func reset() {
        cachedToken = nil
        expiresAt = nil
        refreshTask = nil
    }
    
    private func fetchToken() async throws -> String {
        let result = try await functions
            .httpsCallable("getEbayAccessToken")
            .call()
        
        guard let data = result.data as? [String: Any],
              let accessToken = data["accessToken"] as? String,
              let accessTokenExpiresAt = data["accessTokenExpiresAt"] as? Double
        else {
            throw EbayTokenError.unexpectedResponse
        }
        
        let expiresAt = Date(timeIntervalSince1970: accessTokenExpiresAt / 1000)
        
        self.cachedToken = accessToken
        self.expiresAt = expiresAt
        
        return accessToken
    }
}