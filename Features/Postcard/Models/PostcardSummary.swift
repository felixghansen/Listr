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
    let scannedAt: Date
    let frontImageURL: URL?
    let backImageURL: URL?
    let status: PostcardStatus

    init(from details: PostcardDetails) {
        self.id = details.id ?? UUID().uuidString
        self.title = details.aiData.title
        self.scannedAt = details.scannedAt
        self.frontImageURL = details.frontImageURL
        self.backImageURL = details.backImageURL
        self.status = details.status
    }
}
