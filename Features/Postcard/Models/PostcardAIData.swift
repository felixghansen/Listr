//
//  PostcardAIData.swift
//  Listr
//
//  Created by Felix on 9/25/26.
//

import Foundation

struct PostcardAIData: Codable, Equatable {
    var title: String
    var description: String
    var era: String
    var type: PostcardType
    var publisher: String
    var keywords: [String]
    var condition: String
    var postmarkDate: String
    var mailingOrigin: String
    var ebayCategoryID: Int
    var suggestedPrice: SuggestedPrice
    var confidence: Confidence
    
    enum Confidence: String, Codable, CaseIterable {
        case high
        case medium
        case low
    }

    struct PostcardType: Codable, Equatable {
        var material: String
        var style: String
    }

    struct SuggestedPrice: Codable, Equatable {
        var price: Double
        var auctionStart: Double
    }
}
