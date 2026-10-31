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
    private var cachedToken: String?
    private var expiresAt: Date?
    
    private let functions = Functions.functions()
    private let refreshMargin: TimeInterval = 60
    
    func accessToken() async throws -> String {
        if let cachedToken, let expiresAt, Date().addingTimeInterval(refreshMargin) < expiresAt {
            return cachedToken
        }
        
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

struct EnvironmentTokenProvider: EbayTokenProvider {
    var variableName = "EBAY_SANDBOX_TOKEN"

    func accessToken() async throws -> String {
        guard let token = ProcessInfo.processInfo.environment[variableName], !token.isEmpty else {
            throw EbayTokenError.missingEnvironmentToken
        }
        return token
    }
}
