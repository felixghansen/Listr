//
//  Collection.swift
//  Listr
//
//  Created by Felix on 10/22/25.
//

import SwiftUI

struct Collection: View {
    let postcards: [PostcardSummary]
    @Binding var selectedPostcards: [PostcardDetails]
    
    @ObservedObject var postcardRepository: PostcardRepository
    @State private var loadingIDs: Set<String> = []
    
    private var selectedPostcardIDs: Set<String> {
        Set(selectedPostcards.compactMap { $0.id })
    }

    var body: some View {
        PostcardGallery(
            postcards: postcards,
            isSelected: { postcard in
                return selectedPostcardIDs.contains(postcard.id)
            },
            onSelect: { summary in
                handlePostcardSelection(summary)
            },
            clearSelection: {
                selectedPostcards = []
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handlePostcardSelection(_ postcard: PostcardSummary) {
        let id = postcard.id
        
        #if os(macOS)
        let flags = NSApp.currentEvent?.modifierFlags ?? []
        let isMultiSelecting = flags.contains(.command) || flags.contains(.shift)
        #else
        let isMultiSelecting = false
        #endif

        if isMultiSelecting && selectedPostcardIDs.contains(id) {
            selectedPostcards.removeAll { $0.id == id }
            return
        }
        
        guard !loadingIDs.contains(id) else { return }
        loadingIDs.insert(id)

        Task { @MainActor in
            do {
                let details = try await postcardRepository.getPostcardDetails(id: id)
                if !selectedPostcardIDs.contains(id) {
                    if isMultiSelecting {
                        selectedPostcards.append(details)
                    } else {
                        selectedPostcards = [details]
                    }
                }
                loadingIDs.remove(id)
            } catch {
                loadingIDs.remove(id)
                print("Failed to load postcard details: \(error)")
            }
        }
    }
}
