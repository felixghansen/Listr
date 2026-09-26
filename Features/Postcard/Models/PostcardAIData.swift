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
    var suggestedPriceCAD: SuggestedPriceCAD

    struct PostcardType: Codable, Equatable {
        var material: String
        var style: String
    }

    struct SuggestedPriceCAD: Codable, Equatable {
        var price: Double
        var auctionStart: Double
    }
}
