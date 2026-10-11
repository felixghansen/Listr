//
//  AnalysisProgressPopup.swift
//  Listr
//

import SwiftUI

struct AnalysisProgressPopup: View {
    let analyzed: Int
    let total: Int
    var onCancel: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView(value: Double(min(analyzed, total)), total: Double(max(total, 1))) {
                Text("Analyzing Postcards…")
                    .font(.headline)
            } currentValueLabel: {
                Text("\(analyzed) of \(total) postcards")
            }

            if let onCancel {
                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel, action: onCancel)
                }
            }
        }
        .padding()
        .frame(maxWidth: 400)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
