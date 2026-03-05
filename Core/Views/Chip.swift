//
//  Chip.swift
//  Listr
//
//  Created by Felix on 12/18/25.
//

import Foundation
import SwiftUI

struct Chip: View {
    let text: String
    let style: HierarchicalShapeStyle
    let isSelected: Bool
    var onSelect: (() -> Void)?
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            
            if let onRemove = onRemove, isSelected {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 12))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(.secondary)
        .background(style)
        .cornerRadius(4)
        .onTapGesture {
            onSelect?()
        }
    }
}
