//
//  EbayClient.swift
//  Listr
//
//  Created by Felix on 10/16/26.
//

import Foundation

struct EbayClient {
    let config: EbayConfig
    let tokenProvider: any EbayTokenProvider

    init(config: EbayConfig = .current, tokenProvider: any EbayTokenProvider) {
        self.config = config
        self.tokenProvider = tokenProvider
    }
    
    func createListing(_ postcard: PostcardDetails, defaults: ListingDefaults) async throws -> String {
        try await createOrReplaceInventoryItem(postcard)
        let offerId = try await createOffer(postcard, defaults: defaults)
        let listingId = try await publishOffer(offerId: offerId)
        
        return listingId
    }
    
    func updateListing(_ postcard: PostcardDetails, defaults: ListingDefaults) async throws {
        try await createOrReplaceInventoryItem(postcard)
        _ = try await createOffer(postcard, defaults: defaults) // the createOffer function handles existing offers, in which case it updates them
    }
    
    func deleteListing(_ postcard: PostcardDetails) async throws {
        guard let id = postcard.id else {
            throw EbayClientError.missingPostcardID
        }
        do {
            _ = try await fetchData(path: "/sell/inventory/v1/inventory_item/\(id)", method: "DELETE")
        } catch let error as EbayError where error.errors.contains(where: { $0.errorId == 25710 }) {
            // Already gone on eBay, so there's nothing to delete.
        }
    }
    
    func getFulfillmentPolicies() async throws -> [EbayPolicy] {
        let data = try await fetchData(
            path: "/sell/account/v1/fulfillment_policy?marketplace_id=\(config.marketplaceID)",
            method: "GET"
        )
        
        let response = try JSONDecoder().decode(FulfillmentPoliciesResponse.self, from: data)
        return response.fulfillmentPolicies.map { EbayPolicy(id: $0.fulfillmentPolicyId, name: $0.name) }
    }
    
    func getPaymentPolicies() async throws -> [EbayPolicy] {
        let data = try await fetchData(
            path: "/sell/account/v1/payment_policy?marketplace_id=\(config.marketplaceID)",
            method: "GET"
        )
        
        let response = try JSONDecoder().decode(PaymentPoliciesResponse.self, from: data)
        return response.paymentPolicies.map { EbayPolicy(id: $0.paymentPolicyId, name: $0.name) }
    }
    
    func getReturnPolicies() async throws -> [EbayPolicy] {
        let data = try await fetchData(
            path: "/sell/account/v1/return_policy?marketplace_id=\(config.marketplaceID)",
            method: "GET"
        )
        
        let response = try JSONDecoder().decode(ReturnPoliciesResponse.self, from: data)
        return response.returnPolicies.map { EbayPolicy(id: $0.returnPolicyId, name: $0.name) }
    }
    
    func getInventoryLocations() async throws -> [InventoryLocation] {
        let data = try await fetchData(path: "/sell/inventory/v1/location", method: "GET")
        
        let response = try JSONDecoder().decode(InventoryLocationsResponse.self, from: data)
        return response.locations
    }
    
    func createInventoryLocation(postalCode: String) async throws -> String {
        let key = "listr-\(UUID().uuidString.prefix(8).lowercased())"
        let body = InventoryLocationRequest(
            location: InventoryLocationDetails(
                address: InventoryLocationAddress(postalCode: postalCode, country: config.countryCode)
            ),
            name: "Listr (\(postalCode))"
        )
        _ = try await fetchData(path: "/sell/inventory/v1/location/\(key)", method: "POST", body: body)
        
        return key
    }
    
    private func createOrReplaceInventoryItem(_ postcard: PostcardDetails) async throws {
        guard let id = postcard.id else {
            throw EbayClientError.missingPostcardID
        }
        let item = EbayItem(postcard: postcard)
        _ = try await fetchData(path: "/sell/inventory/v1/inventory_item/\(id)", method: "PUT", body: item)
    }
    
    private func createOffer(_ postcard: PostcardDetails, defaults: ListingDefaults) async throws -> String {
        let offer = try EbayOffer(postcard: postcard, config: config, defaults: defaults)
        
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
        guard let url = URL(string: config.apiBaseURL + path) else {
            throw URLError(.badURL)
        }
        
        let token = try await tokenProvider.accessToken()
        
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
