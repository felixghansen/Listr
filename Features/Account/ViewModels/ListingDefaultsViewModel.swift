//
//  ListingDefaultsViewModel.swift
//  Listr
//
//  Created by Felix on 11/3/26.
//

import Foundation
import SwiftUI

@MainActor
final class ListingDefaultsViewModel: ObservableObject {
    @Published var defaults = ListingDefaults()
    
    @Published private(set) var fulfillmentPolicies: [EbayPolicy] = []
    @Published private(set) var paymentPolicies: [EbayPolicy] = []
    @Published private(set) var returnPolicies: [EbayPolicy] = []
    @Published private(set) var locations: [InventoryLocation] = []
    
    @Published private(set) var hasLoaded: Bool = false
    @Published private(set) var errorMessage: String = ""
    
    private let ebayClient: EbayClient
    private let userRepo: UserRepository
    
    var businessPoliciesURL: URL {
        ebayClient.businessPoliciesURL
    }
    
    init(ebayClient: EbayClient, userRepo: UserRepository) {
        self.ebayClient = ebayClient
        self.userRepo = userRepo
    }
    
    func loadDefaults() async {
        errorMessage = ""
        
        defer { hasLoaded = true }
        
        do {
            async let fulfillment = ebayClient.getFulfillmentPolicies()
            async let payment = ebayClient.getPaymentPolicies()
            async let returns = ebayClient.getReturnPolicies()
            async let ebayLocations = ebayClient.getInventoryLocations()

            (fulfillmentPolicies, paymentPolicies, returnPolicies, locations) =
                try await (fulfillment, payment, returns, ebayLocations)
            
            var loaded = userRepo.listingDefaults ?? ListingDefaults()
            
            loaded.fulfillmentPolicyID = resolvedID(loaded.fulfillmentPolicyID, in: fulfillmentPolicies.map(\.id))
            loaded.paymentPolicyID = resolvedID(loaded.paymentPolicyID, in: paymentPolicies.map(\.id))
            loaded.returnPolicyID = resolvedID(loaded.returnPolicyID, in: returnPolicies.map(\.id))
            loaded.merchantLocationKey = resolvedID(loaded.merchantLocationKey, in: locations.map(\.merchantLocationKey))
            
            defaults = loaded
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func saveDefaults() async {
        guard defaults != userRepo.listingDefaults else { return }
        
        errorMessage = ""
        
        do {
            try await userRepo.saveDefaults(defaults)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createLocation(postalCode: String) async {
        errorMessage = ""
        
        do {
            let key = try await ebayClient.createInventoryLocation(postalCode: postalCode)
            locations = try await ebayClient.getInventoryLocations()
            defaults.merchantLocationKey = key
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func resolvedID(_ current: String?, in ids: [String]) -> String? {
        if let current, ids.contains(current) {
            return current
        }
        return ids.count == 1 ? ids.first : nil
    }
}
