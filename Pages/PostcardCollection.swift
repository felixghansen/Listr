//
//  PostcardCollection.swift
//  Listr
//
//  Created by Felix on 10/22/25.
//

import SwiftUI

struct PostcardCollection: View {
    let postcards: [PostcardSummary]
    @Binding var selectedPostcards: [PostcardDetails]
    let onDelete: ([PostcardDetails]) -> Void

    private let postcardRepo = PostcardRepository.shared
    @State private var loadingIDs: Set<String> = []

    private var selectedIDs: Set<String> {
        Set(selectedPostcards.compactMap(\.id))
    }

    var body: some View {
        PostcardGallery(
            postcards: postcards,
            isSelected: { selectedIDs.contains($0.id) },
            onSelect: handleSelection,
            onDelete: handleDelete,
            clearSelection: { selectedPostcards = [] },
            onReachEnd: loadNextPage
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadNextPage() {
        Task {
            do {
                try await postcardRepo.loadNextPage()
            } catch {
                print("Failed to load more postcards: \(error)")
            }
        }
    }
    
    private func handleDelete(_ clicked: PostcardSummary) {
        if selectedIDs.contains(clicked.id) {
            onDelete(selectedPostcards)
        } else {
            Task {
                do {
                    let details = try await postcardRepo.details(for: clicked.id)
                    onDelete([details])
                } catch {
                    print("Failed to load postcard details: \(error)")
                }
            }
        }
    }

    private func handleSelection(_ postcard: PostcardSummary) {
        let id = postcard.id

        #if os(macOS)
        let flags = NSApp.currentEvent?.modifierFlags ?? []
        let isMultiSelecting = flags.contains(.command) || flags.contains(.shift)
        #else
        let isMultiSelecting = false
        #endif

        if isMultiSelecting && selectedIDs.contains(id) {
            selectedPostcards.removeAll { $0.id == id }
            return
        }

        guard !loadingIDs.contains(id) else { return }
        loadingIDs.insert(id)

        Task {
            defer { loadingIDs.remove(id) }

            do {
                let details = try await postcardRepo.details(for: id)
                guard !selectedIDs.contains(id) else { return }

                if isMultiSelecting {
                    selectedPostcards.append(details)
                } else {
                    selectedPostcards = [details]
                }
            } catch {
                print("Failed to load postcard details: \(error)")
            }
        }
    }
}
