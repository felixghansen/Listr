//
//  EbayPostcardCategory.swift
//  Listr
//
//  Created by Felix on 10/30/26.
//

import Foundation

enum EbayPostcardCategory {
    static let topographical = 262042
    static let nonTopographical = 262043

    static func isValid(_ id: Int) -> Bool {
        id == topographical || id == nonTopographical
    }
}
