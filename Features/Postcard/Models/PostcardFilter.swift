//
//  PostcardFilter.swift
//  Listr
//
//  Created by Felix on 10/21/25.
//

// this file is for filtering all the postcards by storing the filter, sort order, batch filter, everything
import Foundation

struct PostcardFilter: Equatable {
    var status: PostcardStatus? = nil
    var batchFilter: BatchFilter = .none
    var sortOrder: PostcardSortOrder = .scannedAt(descending: true)
    static let unfiltered = PostcardFilter()
}

enum BatchFilter: Equatable {
    case none
    case selected(batches: Set<PostcardBatch>)
    
    var batchIDs: Set<String> {
        switch self {
        case .none:
            return []
        case .selected(let batches):
            return Set(batches.compactMap { $0.id })
        }
    }
    
    var batches: Set<PostcardBatch> {
        switch self {
        case .none:
            return []
        case .selected(let batches):
            return batches
        }
    }
}

enum PostcardSortOrder: Equatable, Hashable {
    case scannedAt(descending: Bool)
    case price(descending: Bool)
    
    var isDescending: Bool {
        switch self {
            case .scannedAt(let descending), .price(let descending):
                return descending
        }
    }
}

extension PostcardSortOrder {
    func isSameType(as other: PostcardSortOrder) -> Bool {
        switch (self, other) {
            case (.scannedAt, .scannedAt), (.price, .price):
                return true
            default:
                return false
        }
    }
}
