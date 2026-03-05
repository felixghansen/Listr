//
//  FilterChips.swift
//  Listr
//
//  Created by Felix on 10/27/25.
//
//
//import Foundation
//import SwiftUI
//
//struct FilterChips: View {
//    @Binding var filter: PostcardFilter
//    
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack {
//                if let status = filter.status {
//                    Chip(text: status.rawValue.capitalized, isSelected: false)
//                }
//                
//                // todo: tag filter
//
//                if filter.batchFilter != .none {
//                    ForEach(Array(filter.batchFilter.batches), id: \.id) { batch in
//                        let batchDate = batch.scannedAt.formatted(date: .abbreviated, time: .omitted)
//                        Chip(text: "Batch \(batchDate)", isSelected: false)
//                    }
//                }
//            }
//        }
//    }
//}


