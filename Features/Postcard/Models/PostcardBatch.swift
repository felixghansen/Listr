//
//  Batch.swift
//  Listr
//
//  Created by Felix on 10/21/25.
//

import Foundation
import FirebaseFirestore

struct PostcardBatch: Codable, Hashable {
    @DocumentID var id: String?
    
    let scannedAt: Date
    let count: Int
    let postcardIDs: [String]
}
