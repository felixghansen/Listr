//
//  Postcard.swift
//  Listr
//
//  Created by Felix on 10/19/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

struct PostcardAIExtractedData: Codable, Equatable {
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

struct PostcardSummary: Identifiable {
    let id: String
    let title: String
    let scannedAt: Date
    let frontImageURL: URL?
    let backImageURL: URL?
    let status: PostcardStatus

    init(from details: PostcardDetails) {
        self.id = details.id ?? UUID().uuidString
        self.title = details.aiData.title
        self.scannedAt = details.scannedAt
        self.frontImageURL = details.frontImageURL
        self.backImageURL = details.backImageURL
        self.status = details.status
    }
}


struct PostcardDetails: Codable, Identifiable {
    @DocumentID var id: String?

    var batchID: String
    var scannedAt: Date
    var status: PostcardStatus
    var frontImageURLString: String
    var backImageURLString: String
    var aiData: PostcardAIExtractedData
    
    var frontImageURL: URL? {
        URL(string: frontImageURLString)
    }

    var backImageURL: URL? {
        URL(string: backImageURLString)
    }
}

enum PostcardStatus: String, Codable, CaseIterable, Equatable {
    case readyToList = "ready to list"
    case needsReview = "needs review"
    case listed = "listed"
    case sold = "sold"
}

extension PostcardStatus {
    var color: Color {
        switch self {
        case .readyToList:
            return .yellow
        case .needsReview:
            return .red
        case .listed:
            return .green
        case .sold:
            return .orange
        }
    }
}

// helper stuff for determing postcard status
extension PostcardDetails {
    private static let unknownTokens = ["", "Unknown", "Unposted", "None"] // todo fix default values, for example when user deletes a field to empty, should it remain blank or default to some value..

    private static func containsUnknownFields(in data: PostcardAIExtractedData) -> Bool {
        let fieldsToCheck = [
            data.era,
            data.type.material,
            data.type.style
        ]

        return fieldsToCheck.contains { value in
            unknownTokens.contains { token in
                value.localizedCaseInsensitiveContains(token)
            }
        }
    }
}

// basic init
extension PostcardDetails {
    init(
        batchID: String,
        scannedAt: Date,
        frontImageURLString: String,
        backImageURLString: String,
        aiData: PostcardAIExtractedData
    ) {
        self.batchID = batchID
        self.scannedAt = scannedAt
        self.frontImageURLString = frontImageURLString
        self.backImageURLString = backImageURLString
        self.aiData = aiData

        self.status = PostcardDetails.containsUnknownFields(in: aiData)
            ? .needsReview
            : .readyToList
    }
}

// converting draft to details
extension PostcardDetails {
    init(updating original: PostcardDetails, with draft: PostcardDetailsDraft){
        self.id = original.id
        self.batchID = original.batchID
        self.scannedAt = original.scannedAt
        self.frontImageURLString = original.frontImageURLString
        self.backImageURLString = original.backImageURLString

        self.aiData = draft.aiData

        self.status = PostcardDetails.containsUnknownFields(in: draft.aiData)
            ? .needsReview
            : .readyToList
    }
}

