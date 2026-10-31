//
//  PostcardStatus.swift
//  Listr
//
//  Created by Felix on 10/31/26.
//

import Foundation
import SwiftUI

enum PostcardStatus: String, Codable, CaseIterable {
    case needsReview = "needs review"
    case readyToList = "ready to list"
    case listed = "listed"
    case sold = "sold"
}

extension PostcardStatus {
    var color: Color {
        switch self {
        case .needsReview:
            return .red
        case .readyToList:
            return .yellow
        case .listed:
            return .blue
        case .sold:
            return .green
        }
    }
}

extension PostcardStatus {
    var menuIcon: Image {
        let config = NSImage.SymbolConfiguration(paletteColors: [NSColor(color)])
        guard let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else {
            return Image(systemName: "circle.fill")
        }
        image.isTemplate = false
        return Image(nsImage: image)
    }
}
