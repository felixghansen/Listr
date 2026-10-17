//
//  EbayClient.swift
//  Listr
//
//  Created by Felix on 10/16/26.
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
    init(postcard: PostcardDetails, sku: String) {
        self.sku = sku
        marketplaceId = "EBAY_US"
        format = "FIXED_PRICE"
        availableQuantity = 1
        categoryId = String(postcard.aiData.ebayCategoryID)
        merchantLocationKey = "listr-test-location"
        
        pricingSummary = PricingSummary(
            price: PricingSummary.Price(value: String(format: "%.2f", postcard.aiData.suggestedPrice.price), currency: "USD")
        )
        
        listingPolicies = ListingPolicies(
            fulfillmentPolicyId: "6258646000",
            paymentPolicyId: "6258647000",
            returnPolicyId: "6258648000"
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

struct EbayClient {
    let baseURL: String
    let token: String
    
    func createListing(_ postcard: PostcardDetails) async throws -> String {
        try await createOrReplaceInventoryItem(postcard)
        let offerId = try await createOffer(postcard)
        let listingId = try await publishOffer(offerId: offerId)
        
        return listingId
    }
    
    func updateListing(_ postcard: PostcardDetails) async throws {
        try await createOrReplaceInventoryItem(postcard)
        let _ = try await createOffer(postcard) // the createOffer function handles existing offers, in which case it updates them
    }
    
    private func createOrReplaceInventoryItem(_ postcard: PostcardDetails) async throws {
        guard let id = postcard.id else {
            throw EbayClientError.missingPostcardID
        }
        let item = EbayItem(postcard: postcard)
        _ = try await fetchData(path: "/sell/inventory/v1/inventory_item/\(id)", method: "PUT", body: item)
    }
    
    private func createOffer(_ postcard: PostcardDetails) async throws -> String {
        guard let id = postcard.id else {
            throw EbayClientError.missingPostcardID
        }
        
        let offer = EbayOffer(postcard: postcard, sku: id)
        
        do {
            let data = try await fetchData(path: "/sell/inventory/v1/offer", method: "POST", body: offer)
            let response = try JSONDecoder().decode(EbayOfferResponse.self, from: data)
            return response.offerId
        } catch let error as EbayError {
            let existingOfferId = error.errors
                .flatMap { $0.parameters ?? [] }
                .first { $0.name == "offerId" }?
                .value
            
            if let existingOfferId {
                // overwrite old offer with current one
                let _ = try await fetchData(path: "/sell/inventory/v1/offer/\(existingOfferId)", method: "PUT", body: offer)
                return existingOfferId
            }
            
            throw error
        }
    }
    
    private func publishOffer(offerId: String) async throws -> String {
        let data = try await fetchData(path: "/sell/inventory/v1/offer/\(offerId)/publish", method: "POST")
        let response = try JSONDecoder().decode(EbayPublishResponse.self, from: data)
        
        return response.listingId
    }
    
    private func fetchData(path: String, method: String, body: (any Encodable)? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en-US", forHTTPHeaderField: "Content-Language")
        
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        let code = httpResponse.statusCode
        guard (200..<300).contains(code) else {
            if let ebayError = try? JSONDecoder().decode(EbayError.self, from: data) {
                throw ebayError
            }
            throw URLError(.badServerResponse)
        }
        
        
        return data
    }
}
