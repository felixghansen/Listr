//
//  EbayConfig.swift
//  Listr
//
//  Created by Felix on 10/30/26.
//

import Foundation

struct EbayConfig {
    let apiBaseURLString: String
    let authorizeURL: URL
    let websiteURL: URL
    let businessPoliciesURL: URL
    let clientID: String
    let ruName: String
    let scopes: [String]

    let marketplaceID: String
    let countryCode: String
    let currency: String

    func listingURL(for listingID: String) -> URL {
        websiteURL.appending(path: "itm/\(listingID)")
    }

    static let sandbox = EbayConfig(
        apiBaseURLString: "https://api.sandbox.ebay.com",
        authorizeURL: URL(string: "https://auth.sandbox.ebay.com/oauth2/authorize")!,
        websiteURL: URL(string: "https://sandbox.ebay.com")!,
        businessPoliciesURL: URL(string: "https://www.sandbox.ebay.com/bp/manage")!,
        clientID: "FelixHan-Listr-SBX-81d2ad8ad-beecadaf",
        ruName: "Felix_Hansen-FelixHan-Listr--cueveor",
        scopes: [
            "https://api.ebay.com/oauth/api_scope",
            "https://api.ebay.com/oauth/api_scope/sell.inventory",
            "https://api.ebay.com/oauth/api_scope/sell.account",
            "https://api.ebay.com/oauth/api_scope/sell.fulfillment.readonly"
        ],
        marketplaceID: "EBAY_US",
        countryCode: "US",
        currency: "USD"
    )

    static let current = EbayConfig.sandbox
}
