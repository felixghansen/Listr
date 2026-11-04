//
//  ListingDefaults.swift
//  Listr
//
//  Created by Felix on 11/3/26.
//

import Foundation

struct ListingDefaults: Codable, Equatable {
    var fulfillmentPolicyID: String?
    var paymentPolicyID: String?
    var returnPolicyID: String?
    var merchantLocationKey: String?
}

extension ListingDefaults {
    var isComplete: Bool {
        return (
            fulfillmentPolicyID != nil &&
            paymentPolicyID != nil &&
            returnPolicyID != nil &&
            merchantLocationKey != nil
        )
    }
}
