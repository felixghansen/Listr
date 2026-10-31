//
//  EbayTokenProvider.swift
//  Listr
//
//  Created by Felix on 10/30/26.
//

import Foundation

protocol EbayTokenProvider: Sendable {
    func accessToken() async throws -> String
}

enum EbayTokenError: LocalizedError {
    case missingToken

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "No eBay token found. Set EBAY_SANDBOX_TOKEN in the Xcode scheme."
        }
    }
}

actor CloudFunctionTokenProvider: EbayTokenProvider {
    func accessToken() async throws -> String {
        // TODO: Use cloud function to get refresh token from firestore
        return ""
    }
}

struct EnvironmentTokenProvider: EbayTokenProvider {
    var variableName = "EBAY_SANDBOX_TOKEN"

    func accessToken() async throws -> String {
        guard let token = ProcessInfo.processInfo.environment[variableName], !token.isEmpty else {
            throw EbayTokenError.missingToken
        }
        return token
    }
}
