//
//  EbayAuthService.swift
//  Listr
//
//  Created by Felix on 10/28/26.
//

import SwiftUI
import AuthenticationServices
import FirebaseFunctions

enum EbayAuthError: LocalizedError {
    case cancelled
    case stateMismatch
    case missingCode
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "eBay connection was cancelled."
        case .stateMismatch:
            return "Something went wrong verifying the eBay sign-in. Please try again."
        case .missingCode:
            return "eBay didn't return a sign-in code. Please try again."
        case .unexpectedResponse:
            return "Couldn't finish connecting your eBay account. Please try again."
        }
    }
}

@MainActor
final class EbayAuthService: ObservableObject {
    static let shared = EbayAuthService()
    private lazy var functions = Functions.functions()
    private init() {}

    @Published private(set) var isConnected = false
    private var pendingState: String?

    // TODO: switch to production host, client ID and RuName
    private let authorizeURL = "https://auth.sandbox.ebay.com/oauth2/authorize"
    private let clientID = "FelixHan-Listr-SBX-81d2ad8ad-beecadaf"
    private let ruName = "Felix_Hansen-FelixHan-Listr--cueveor"
    private let scopes = [
        "https://api.ebay.com/oauth/api_scope",
        "https://api.ebay.com/oauth/api_scope/sell.inventory",
        "https://api.ebay.com/oauth/api_scope/sell.account"
    ]

    func connect(using session: WebAuthenticationSession) async throws {
        let state = UUID().uuidString
        pendingState = state

        let callbackURL = try await session.authenticate(
            using: signInURL(state: state),
            callbackURLScheme: "listr"
        )

        let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        if value("error") != nil {
            throw EbayAuthError.cancelled
        }
        guard value("state") == pendingState else {
            throw EbayAuthError.stateMismatch
        }
        guard let code = value("code") else {
            throw EbayAuthError.missingCode
        }

        pendingState = nil
        
        let result = try await functions
            .httpsCallable("exchangeEbayCode")
            .call(["code": code])
        
        guard let data = result.data as? [String: Any], data["success"] as? Bool == true else {
            throw EbayAuthError.unexpectedResponse
        }
        
        isConnected = true
    }

    func disconnect() {
        // TODO: delete the stored refresh token via a Cloud Function
        isConnected = false
    }

    private func signInURL(state: String) -> URL {
        var components = URLComponents(string: authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: ruName),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state)
        ]
        return components.url!
    }
}
