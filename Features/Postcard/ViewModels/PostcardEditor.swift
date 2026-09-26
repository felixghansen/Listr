//
//  PostcardEditor.swift
//  Listr
//
//  Created by Felix on 10/21/25.
//

import SwiftUI

// holds the original and draft copy of the postcard details
@MainActor
final class PostcardEditor: ObservableObject {
    private var original: PostcardDetails
    @Published var draft: PostcardAIData

    var hasChanges: Bool {
        draft != original.aiData
    }

    init(postcard: PostcardDetails) {
        original = postcard
        draft = postcard.aiData
    }

    func reset(with postcard: PostcardDetails) {
        original = postcard
        draft = postcard.aiData
    }
    
    func commitAndReset() -> PostcardDetails {
        var updated = original
        updated.update(aiData: draft)
        reset(with: updated)
        return updated
    }
}
