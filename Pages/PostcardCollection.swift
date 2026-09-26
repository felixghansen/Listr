//
//  PostcardCollection.swift
//  Listr
//
//  Created by Felix on 10/22/25.
//

import SwiftUI

struct PostcardCollection: View {
    let postcards: [PostcardSummary]
    @Binding var selectedIDs: Set<String>
    @State private var anchorID: String?

    var body: some View {
        PostcardGallery(
            postcards: postcards,
            isSelected: { selectedIDs.contains($0.id) },
            onSelect: { handleselectedIDs($0.id) },
            clearSelectedIDs: { selectedIDs = [] }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleselectedIDs(_ id: String) {
        #if os(macOS)
        let flags = NSApp.currentEvent?.modifierFlags ?? []
        #endif

        if flags.contains(.command) {
            if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
            anchorID = id
        } else if flags.contains(.shift), let anchor = anchorID,
                  let start = postcards.firstIndex(where: { $0.id == anchor }),
                  let end = postcards.firstIndex(where: { $0.id == id }) {
            let range = min(start, end)...max(start, end)
            selectedIDs = Set(postcards[range].map(\.id))
        } else {
            selectedIDs = [id]
            anchorID = id
        }
    }
}
