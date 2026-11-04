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
    
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String = ""
    
    private let ebayClient: EbayClient
    private let userRepo: UserRepository
    
    init(ebayClient: EbayClient, userRepo: UserRepository) {
        self.ebayClient = ebayClient
        self.userRepo = userRepo
    }
    
    func loadDefaults() async {
        isLoading = true
        errorMessage = ""
        
        defer { isLoading = false }
        
        do {
            async let fulfillmentPolicies = ebayClient.getFulfillmentPolicies()
            async let paymentPolicies = ebayClient.getPaymentPolicies()
            async let returnPolicies = ebayClient.getReturnPolicies()
            async let locations = ebayClient.getInventoryLocations()
            
            defaults = userRepo.listingDefaults ?? ListingDefaults()
            (self.fulfillmentPolicies, self.paymentPolicies, self.returnPolicies, self.locations) = try await (fulfillmentPolicies, paymentPolicies, returnPolicies, locations)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func saveDefaults() async {
        isLoading = true
        errorMessage = ""
        
        defer { isLoading = false }
        
        do {
            guard defaults != userRepo.listingDefaults else { return }
            try await userRepo.saveDefaults(defaults)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createLocation(postalCode: String) async {
        isLoading = true
        errorMessage = ""
        
        defer { isLoading = false }
        
        do {
            let key = try await ebayClient.createInventoryLocation(postalCode: postalCode)
            locations = try await ebayClient.getInventoryLocations()
            defaults.merchantLocationKey = key
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
