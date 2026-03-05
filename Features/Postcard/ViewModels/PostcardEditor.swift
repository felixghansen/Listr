//
//  PostcardEditor.swift
//  Listr
//
//  Created by Felix on 10/21/25.
//

import SwiftUI

@MainActor
final class PostcardEditor: ObservableObject {
    private var original: PostcardDetails
    @Published var draft: PostcardDetailsDraft

    var hasChanges: Bool {
        draft.aiData != original.aiData
    }
    
    init(postcard: PostcardDetails) {
        self.original = postcard
        self.draft = PostcardDetailsDraft(from: postcard)
    }

    func reset(with postcard: PostcardDetails) {
        self.original = postcard
        self.draft = PostcardDetailsDraft(from: postcard)
    }

    func commitAndReset() -> PostcardDetails? {
        guard let updated = commit() else { return nil }
        reset(with: updated)

        return updated
    }
    
    private func commit() -> PostcardDetails? {
        guard draft.id == original.id else {
            assert(draft.id == original.id)
            return nil
        }

        return PostcardDetails(updating: original, with: draft)
    }
}
