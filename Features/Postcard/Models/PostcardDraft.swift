//
//  PostcardDraft.swift
//  Listr
//
//  Created by Felix on 12/23/25.
//

import Foundation

struct PostcardDetailsDraft {
    let id: String?
    var aiData: PostcardAIExtractedData
}

extension PostcardDetailsDraft {
    init(from details: PostcardDetails) {
        self.aiData = details.aiData
        self.id = details.id
    }
}
