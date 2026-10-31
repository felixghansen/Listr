//
//  PostcardFilter.swift
//  Listr
//
//  Created by Felix on 10/21/25.
//

import Foundation

struct PostcardSortOrder: Equatable {
    var field: Field = .dateScanned
    var descending = true

    enum Field: String, CaseIterable, Identifiable {
        case dateScanned = "Date Scanned"
        case price = "Price"

        var id: Self { self }
    }
}
