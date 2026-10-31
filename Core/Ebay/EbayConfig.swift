//
//  EbayConfig.swift
//  Listr
//
//  Created by Felix on 10/30/26.
//

import Foundation

struct EbayConfig {
    let apiBaseURL: String
    let authorizeURL: String
    let websiteURL: String
    let clientID: String
    let ruName: String
    let scopes: [String]

    let marketplaceID: String
    let currency: String

    // TODO: These belong to the Sandbox test seller. Real sellers each have their own,
    // so look them up per user (Account API) and store them once real sign-in works.
    let merchantLocationKey: String
    let fulfillmentPolicyID: String
    let paymentPolicyID: String
    let returnPolicyID: String

    func listingURL(for listingID: String) -> URL? {
        URL(string: "\(websiteURL)/itm/\(listingID)")
    }

    static let sandbox = EbayConfig(
        apiBaseURL: "https://api.sandbox.ebay.com",
        authorizeURL: "https://auth.sandbox.ebay.com/oauth2/authorize",
        websiteURL: "https://sandbox.ebay.com",
        clientID: "FelixHan-Listr-SBX-81d2ad8ad-beecadaf",
        ruName: "Felix_Hansen-FelixHan-Listr--cueveor",
        scopes: [
            "https://api.ebay.com/oauth/api_scope",
            "https://api.ebay.com/oauth/api_scope/sell.inventory",
            "https://api.ebay.com/oauth/api_scope/sell.account"
        ],
        marketplaceID: "EBAY_US",
        currency: "USD",
        merchantLocationKey: "listr-test-location",
        fulfillmentPolicyID: "6258646000",
        paymentPolicyID: "6258647000",
        returnPolicyID: "6258648000"
    )

    static let current = EbayConfig.sandbox
}
