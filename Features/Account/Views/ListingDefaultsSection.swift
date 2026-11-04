//
//  LiftingDefaultsSection.swift
//  Listr
//
//  Created by Felix on 11/3/26.
//

import Foundation
import SwiftUI

struct ListingDefaultsSection: View {
    @StateObject private var listingDefaultsVM = ListingDefaultsViewModel(
        ebayClient: EbayClient(tokenProvider: CloudFunctionTokenProvider.shared),
        userRepo: UserRepository.shared
    )
    
    var body: some View {
        Section {
            Picker("Shipping", selection: $listingDefaultsVM.defaults.fulfillmentPolicyID) {
                Text("…").tag(String?.none)
                ForEach(listingDefaultsVM.fulfillmentPolicies) { policy in
                    Text(policy.name).tag(Optional(policy.id))
                }
            }
            Picker("Payment", selection: $listingDefaultsVM.defaults.paymentPolicyID) {
                Text("…").tag(String?.none)
                ForEach(listingDefaultsVM.paymentPolicies) { policy in
                    Text(policy.name).tag(Optional(policy.id))
                }
            }
            Picker("Returns", selection: $listingDefaultsVM.defaults.returnPolicyID) {
                Text("…").tag(String?.none)
                ForEach(listingDefaultsVM.returnPolicies) { policy in
                    Text(policy.name).tag(Optional(policy.id))
                }
            }
            Picker("Ships From", selection: $listingDefaultsVM.defaults.merchantLocationKey) {
                Text("…").tag(String?.none)
                ForEach(listingDefaultsVM.locations) { location in
                    Text(location.displayName).tag(Optional(location.merchantLocationKey))
                }
            }
        } header: {
            Text("Listing Defaults")
        } footer: {
            Text("Used for every postcard Listr lists. Manage your policies in eBay Seller Hub.")
        }
        .onAppear {
            Task {
                await listingDefaultsVM.loadDefaults()
            }
        }
        .onChange(of: listingDefaultsVM.defaults) {
            Task {
                await listingDefaultsVM.saveDefaults()
            }
        }
    }
}
