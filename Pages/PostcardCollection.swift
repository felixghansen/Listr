//
//  PostcardCollection.swift
//  Listr
//
//  Created by Felix on 10/22/25.
//

import SwiftUI

struct PostcardCollection: View {
    let postcards: [PostcardSummary]
    @Binding var selection: Set<String>
    @State private var anchorID: String?

    var body: some View {
        PostcardGallery(
            postcards: postcards,
            isSelected: { selection.contains($0.id) },
            onSelect: { handleSelection($0.id) },
            clearSelection: { selection = [] }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleSelection(_ id: String) {
        #if os(macOS)
        let flags = NSApp.currentEvent?.modifierFlags ?? []
        #endif

        if flags.contains(.command) {
            if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
            anchorID = id
        } else if flags.contains(.shift), let anchor = anchorID,
                  let start = postcards.firstIndex(where: { $0.id == anchor }),
                  let end = postcards.firstIndex(where: { $0.id == id }) {
            let range = min(start, end)...max(start, end)
            selection = Set(postcards[range].map(\.id))
        } else {
            selection = [id]
            anchorID = id
        }
    }
}
