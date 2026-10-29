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
    let frontImageURL: URL? // TODO: Change this to a smaller, thumnail version
    let status: PostcardStatus

    init(from details: PostcardDetails) {
        self.id = details.id ?? UUID().uuidString
        self.title = details.aiData.title
        self.frontImageURL = details.frontImageURL
        self.status = details.status
    }
}
