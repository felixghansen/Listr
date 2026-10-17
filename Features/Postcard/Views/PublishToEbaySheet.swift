//
//  PublishToEbaySheet.swift
//  Listr
//
//  Created by Felix on 10/14/26.
//

import SwiftUI

enum ListingState: Equatable {
    case listing
    case listed
    case failed(String)
}

struct PublishToEbaySheet: View {
    let postcards: [PostcardDetails]
    var listPostcard: (PostcardDetails) async throws -> Void

    @Environment(\.dismiss) private var dismiss

    private var ready: [PostcardDetails] {
        postcards.filter { $0.status == .readyToList }
    }

    private var skipped: [PostcardDetails] {
        postcards.filter { $0.status != .readyToList }
    }
    
    @State private var isPublishing = false
    @State private var listingStates: [String: ListingState] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("List on eBay")
                .font(.headline)

            if !ready.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Will be listed (\(ready.count))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(ready) { postcard in
                                HStack(spacing: 10) {
                                    PostcardImage(url: postcard.frontImageURL, scaledTo: .fit)
                                        .frame(width: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(postcard.aiData.title)
                                            .lineLimit(2)
                                        if case .failed(let message) = listingStates[postcard.id ?? ""] {
                                            Text(message)
                                                .font(.caption)
                                                .foregroundStyle(.red)
                                                .lineLimit(3)
                                                .textSelection(.enabled)
                                        }
                                    }

                                    Text(postcard.aiData.suggestedPrice.price, format: .currency(code: "USD"))
                                        .font(.callout.monospacedDigit())
                                    
                                    HStack(spacing: 10) {
                                        Group {
                                            switch listingStates[postcard.id ?? ""] {
                                            case .listing:
                                                ProgressView()
                                                    .controlSize(.small)
                                            case .listed:
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                            case .failed:
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundStyle(.orange)
                                            case nil:
                                                Color.clear
                                            }
                                        }
                                        .frame(width: 18)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(maxHeight: 250)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            if !skipped.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Not ready to list (\(skipped.count))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(skipped) { postcard in
                                HStack(spacing: 10) {
                                    PostcardImage(url: postcard.frontImageURL, scaledTo: .fit)
                                        .frame(width: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                                    Text(postcard.aiData.title)
                                        .font(.callout)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.horizontal, 8)
                        .opacity(0.45)
                    }
                    .frame(maxHeight: 250)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(ready.count == 1 ? "List 1 Postcard" : "List \(ready.count) Postcards") {
                    isPublishing = true
                    
                    Task {
                        for postcard in ready {
                            guard let id = postcard.id else { continue }
                            listingStates[id] = .listing
                            
                            do {
                                try await listPostcard(postcard)
                                listingStates[id] = .listed
                            } catch {
                                listingStates[id] = .failed(error.localizedDescription)
                                print(error)
                            }
                        }
                        
                        isPublishing = false
                        
                        let allSucceeded = listingStates.values.allSatisfy { $0 == .listed }
                        if allSucceeded {
                            dismiss()
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(ready.isEmpty || isPublishing)
            }
        }
        .padding(16)
        .frame(width: 500)
    }
}
