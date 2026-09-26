//
//  PostcardFilter.swift
//  Listr
//
//  Created by Felix on 10/21/25.
//

import Foundation

enum PostcardSortOrder: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case priceHigh = "Price: High to Low"
    case priceLow = "Price: Low to High"

    var id: Self { self }
}
