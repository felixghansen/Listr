//
//  PublishToEbaySheet.swift
//  Listr
//
//  Created by Felix on 10/14/26.
//

import SwiftUI

struct PublishToEbaySheet: View {
    let postcards: [PostcardDetails]
    var onPublish: ([PostcardDetails]) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss

    private var ready: [PostcardDetails] {
        postcards.filter { $0.status == .readyToList }
    }

    private var skipped: [PostcardDetails] {
        postcards.filter { $0.status != .readyToList }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("List on eBay")
                .font(.headline)

            if !ready.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Will be listed (\(ready.count))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(ready) { postcard in
                                HStack(spacing: 10) {
                                    PostcardImage(url: postcard.frontImageURL, scaledTo: .fit)
                                        .frame(width: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                                    Text(postcard.aiData.title)
                                        .font(.callout)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text(postcard.aiData.suggestedPriceCAD.price, format: .currency(code: "CAD"))
                                        .font(.callout.monospacedDigit())
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(maxHeight: 250)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            if !skipped.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Not ready to list (\(skipped.count))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(skipped) { postcard in
                                HStack(spacing: 10) {
                                    PostcardImage(url: postcard.frontImageURL, scaledTo: .fit)
                                        .frame(width: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                                    Text(postcard.aiData.title)
                                        .font(.callout)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.horizontal, 8)
                        .opacity(0.45)
                    }
                    .frame(maxHeight: 250)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Publish \(ready.count)") {
                    onPublish(ready)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(ready.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 500)
    }
}
