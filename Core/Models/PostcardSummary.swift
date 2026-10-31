//
//  PostcardSummary.swift
//  Listr
//
//  Created by Felix on 9/25/26.
//

import Foundation

struct PostcardSummary: Identifiable {
    let id: String
    let title: String
    let frontImageThumbnailURL: URL?
    let status: PostcardStatus

    init(from details: PostcardDetails) {
        self.id = details.id ?? UUID().uuidString
        self.title = details.aiData.title
        self.frontImageThumbnailURL = details.frontImageThumbnailURL
        self.status = details.status
    }
}
