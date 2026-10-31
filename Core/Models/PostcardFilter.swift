//
//  PostcardFilter.swift
//  Listr
//
//  Created by Felix on 10/31/26.
//

import Foundation

struct PostcardFilter: Hashable {
    var status: PostcardStatus?
    var batchID: String?
    
    static let all = PostcardFilter(status: nil, batchID: nil)
}
