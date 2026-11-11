//
//  ListingDefaultsSection.swift
//  Listr
//
//  Created by Felix on 11/3/26.
//

import SwiftUI

struct ListingDefaultsSection: View {
    @StateObject private var listingDefaultsVM = ListingDefaultsViewModel(
        ebayClient: EbayClient(tokenProvider: CloudFunctionTokenProvider.shared),
        userRepo: UserRepository.shared
    )

    @State private var isAddingLocation = false
    private let newLocationTag = "__newLocation__"

    var body: some View {
        Section {
            if !listingDefaultsVM.hasLoaded {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading eBay settings…")
                        .foregroundStyle(.secondary)
                }
            } else {
                policyPicker(
                    "Shipping",
                    selection: $listingDefaultsVM.defaults.fulfillmentPolicyID,
                    policies: listingDefaultsVM.fulfillmentPolicies
                )
                policyPicker(
                    "Payment",
                    selection: $listingDefaultsVM.defaults.paymentPolicyID,
                    policies: listingDefaultsVM.paymentPolicies
                )
                policyPicker(
                    "Returns",
                    selection: $listingDefaultsVM.defaults.returnPolicyID,
                    policies: listingDefaultsVM.returnPolicies
                )

                Picker("Ships From", selection: locationSelection) {
                    Text("None").tag(String?.none)
                    ForEach(listingDefaultsVM.locations) { location in
                        Text(location.displayName).tag(Optional(location.merchantLocationKey))
                    }
                    Divider()
                    Text("New Location…").tag(Optional(newLocationTag))
                }

                if isAddingLocation {
                    NewLocationRow(
                        onCreate: { postalCode in
                            await listingDefaultsVM.createLocation(postalCode: postalCode)
                            
                            if listingDefaultsVM.errorMessage.isEmpty {
                                withAnimation { isAddingLocation = false }
                            }
                        },
                        onClose: {
                            withAnimation { isAddingLocation = false }
                        }
                    )
                }
            }
        } header: {
            Text("Listing Defaults")
        } footer: {
            if listingDefaultsVM.errorMessage.isEmpty {
                Text(footerText)
            } else {
                Text(listingDefaultsVM.errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .task {
            await listingDefaultsVM.loadDefaults()
        }
        .onChange(of: listingDefaultsVM.defaults) {
            Task {
                await listingDefaultsVM.saveDefaults()
            }
        }
    }
    
    private var footerText: AttributedString {
        var text = AttributedString("Used for every postcard Listr lists. ")
        var link = AttributedString("Manage Policies in Seller Hub")
        link.link = listingDefaultsVM.businessPoliciesURL
        text.append(link)
        return text
    }

    private var locationSelection: Binding<String?> {
        Binding(
            get: { listingDefaultsVM.defaults.merchantLocationKey },
            set: { newValue in
                if newValue == newLocationTag {
                    withAnimation { isAddingLocation = true }
                } else {
                    listingDefaultsVM.defaults.merchantLocationKey = newValue
                }
            }
        )
    }

    private func policyPicker(
        _ title: String,
        selection: Binding<String?>,
        policies: [EbayPolicy]
    ) -> some View {
        Picker(title, selection: selection) {
            Text("None").tag(String?.none)
            ForEach(policies) { policy in
                Text(policy.name).tag(Optional(policy.id))
            }
        }
    }
}

private struct NewLocationRow: View {
    let onCreate: (String) async -> Void
    let onClose: () -> Void

    @State private var postalCode = ""
    @State private var isCreating = false

    private var isValidPostalCode: Bool {
        postalCode.count == 5 && postalCode.allSatisfy(\.isNumber)
    }

    var body: some View {
        LabeledContent("New Location") {
            HStack {
                TextField("ZIP Code", text: $postalCode, prompt: Text("ZIP code"))
                    .labelsHidden()
                    .frame(width: 90)
                    .onSubmit(create)

                if isCreating {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("Cancel", action: onClose)
                    .disabled(isCreating)

                Button("Add", action: create)
                    .disabled(!isValidPostalCode || isCreating)
            }
        }
    }

    private func create() {
        guard isValidPostalCode, !isCreating else { return }
        isCreating = true
        
        Task {
            defer { isCreating = false }
            await onCreate(postalCode)
        }
    }
}
