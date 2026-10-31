//
//  PostcardCollectionViewModel.swift
//  Listr
//
//  Created by Felix on 10/31/26.
//

import Foundation
import SwiftUI

@MainActor
final class PostcardCollectionViewModel: ObservableObject {
    private let postcardRepo: PostcardRepository
    private let ebayClient: EbayClient
    
    init(postcardRepo: PostcardRepository? = nil, ebayClient: EbayClient) {
        self.postcardRepo = postcardRepo ?? .shared
        self.ebayClient = ebayClient
    }
    
    @Published var filter: PostcardFilter = .all
    @Published var sortOrder = PostcardSortOrder()
    @Published var searchText = ""
    @Published var selectedPostcards: [PostcardDetails] = []
    
    var visiblePostcards: [PostcardSummary] {
        guard !searchText.isEmpty else { return postcardRepo.postcards }
        return postcardRepo.postcards.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    func startListening() {
        postcardRepo.listen(to: filter, sortedBy: sortOrder)
    }

    func stopListening() {
        postcardRepo.stopListening()
    }
    
    func loadNextPage() {
        Task {
            do { try await postcardRepo.loadNextPage() }
            catch { print("Failed to load more postcards: \(error)") }
        }
    }

    func savePostcard(_ postcard: PostcardDetails) async throws {
        try await postcardRepo.updatePostcard(postcard)
        replaceInSelection(postcard)
    }
    
    private func replaceInSelection(_ postcard: PostcardDetails) {
        if let index = selectedPostcards.firstIndex(where: { $0.id == postcard.id }) {
            selectedPostcards[index] = postcard
        }
    }
    
    func updateListing(_ postcard: PostcardDetails) async throws {
        try await ebayClient.updateListing(postcard)
    }
    
    func listPostcard(_ postcard: PostcardDetails) async throws {
        let listingId = try await ebayClient.createListing(postcard)
        
        var updatedPostcard = postcard
        updatedPostcard.markListed(listingId: listingId)
        
        try await savePostcard(updatedPostcard)
    }
    
    func deletePostcards(_ postcards: [PostcardDetails]) async throws {
        var postcardsToDelete: [PostcardDetails] = []
        var firstError: Error?
        
        for postcard in postcards {
            if postcard.status == .listed {
                do {
                    try await ebayClient.deleteListing(postcard)
                } catch {
                    firstError = firstError ?? error
                    continue
                }
            }
            
            postcardsToDelete.append(postcard)
        }
        
        if !postcardsToDelete.isEmpty {
            try await postcardRepo.deletePostcards(postcardsToDelete)
        }
        
        selectedPostcards.removeAll { selected in
            postcardsToDelete.contains { $0.id == selected.id }
        }
        
        if let firstError {
            throw firstError
        }
    }
    
    
}

