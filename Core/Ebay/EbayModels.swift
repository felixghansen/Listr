//
//  EbayModels.swift
//  Listr
//
//  Created by Felix on 10/30/26.
//

import Foundation

struct EbayError: Decodable, Error {
    let errors: [Item]
    
    struct Item: Decodable {
        let errorId: Int
        let message: String
        let longMessage: String?
        let parameters: [Parameter]?
        
        struct Parameter: Decodable {
            let name: String
            let value: String
        }
    }
}

extension EbayError: LocalizedError {
    var errorDescription: String? {
        errors
            .map { $0.longMessage ?? $0.message }
            .joined(separator: "\n")
    }
}

enum EbayClientError: Error {
    case missingPostcardID
    case offerNotFound
}

extension EbayClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingPostcardID:
            return "This postcard hasn't been saved yet. Try again in a moment."
        case .offerNotFound:
            return "Couldn't find this postcard's existing eBay offer."
        }
    }
}

struct EbayItem: Encodable {
    let availability: Availability
    let condition: String
    let conditionDescription: String
    let product: Product

    struct Availability: Encodable {
        let shipToLocationAvailability: ShipToLocationAvailability
    }

    struct ShipToLocationAvailability: Encodable {
        let quantity: Int
    }

    struct Product: Encodable {
        let title: String
        let description: String
        let imageUrls: [String]
        let aspects: [String: [String]]
    }
}

extension EbayItem {
    init(postcard: PostcardDetails) {
        let aiData = postcard.aiData

        availability = Availability(
            shipToLocationAvailability: ShipToLocationAvailability(quantity: 1)
        )

        condition = "USED_EXCELLENT"
        conditionDescription = aiData.condition

        var aspects: [String: [String]] = [
            "Era": [aiData.era],
            "Type": [aiData.type.material],
            "Features": [aiData.type.style],
            "Postage Condition": [aiData.postmarkDate == "Unposted" ? "Unposted" : "Posted"],
            "Unit of Sale": ["Single Unit"],
            "Original/Licensed Reprint": ["Original"]
        ]

        if aiData.publisher != "Unknown" {
            aspects["Brand/Publisher"] = [String(aiData.publisher.prefix(65))]
        }
        
        product = Product(
            title: String(aiData.title.prefix(80)),
            description: aiData.description,
            imageUrls: [postcard.frontImageURLString, postcard.backImageURLString], // TODO: use Media API to make images depend on eBay's service and not firebase's
            aspects: aspects
        )
    }
}

struct EbayOffer: Encodable {
    let sku: String
    let marketplaceId: String
    let format: String
    let availableQuantity: Int
    let categoryId: String
    let merchantLocationKey: String
    let pricingSummary: PricingSummary
    let listingPolicies: ListingPolicies
    
    struct PricingSummary: Encodable {
        let price: Price
        
        struct Price: Encodable {
            let value: String
            let currency: String
        }
    }
    
    struct ListingPolicies: Encodable {
        let fulfillmentPolicyId: String
        let paymentPolicyId: String
        let returnPolicyId: String
    }
}

extension EbayOffer {
    init(postcard: PostcardDetails, sku: String, config: EbayConfig) {
        self.sku = sku
        marketplaceId = config.marketplaceID
        format = "FIXED_PRICE"
        availableQuantity = 1
        categoryId = String(postcard.aiData.ebayCategoryID)
        merchantLocationKey = config.merchantLocationKey
        
        pricingSummary = PricingSummary(
            price: PricingSummary.Price(
                value: String(format: "%.2f", postcard.aiData.suggestedPrice.price),
                currency: config.currency
            )
        )
        
        listingPolicies = ListingPolicies(
            fulfillmentPolicyId: config.fulfillmentPolicyID,
            paymentPolicyId: config.paymentPolicyID,
            returnPolicyId: config.returnPolicyID
        )
    }
}

struct EbayOfferResponse: Decodable {
    let offerId: String
}

struct EbayOffersResponse: Decodable {
    let offers: [EbayOfferResponse]
}

struct EbayPublishResponse: Decodable {
    let listingId: String
}
