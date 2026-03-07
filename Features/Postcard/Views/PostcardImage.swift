//
//  PostcardImage.swift
//  Listr
//
//  Created by Felix on 10/31/25.
//

import Foundation
import SwiftUI

enum ImageScale {
    case fit, fill
}

struct PostcardImage: View {
    let url: URL?
    let scaledTo: ImageScale

    @StateObject private var loader = ImageLoader(url: nil)

    var body: some View {
        Group {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: scaledTo == .fill ? .fill : .fit)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .separatorColor))
                    .overlay(ProgressView())
            }
        }
        .clipped()
        .onAppear {
            loader.update(url: url)
        }
        .onChange(of: url) { _, newURL in
            loader.update(url: newURL)
        }
    }
}

struct ImageCarousel: View {
    let imageURLs: [URL?]
    let containerWidth: CGFloat

    private let aspectRatio: CGFloat = 3 / 2
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 12) {

            ScrollViewReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                            PostcardImage(url: imageURL, scaledTo: .fit)
                                .frame(width: containerWidth)
                                .aspectRatio(aspectRatio, contentMode: .fit)
                                .id(index)
                        }
                    }
                }
                .scrollDisabled(true)
                .onChange(of: currentIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        geo.scrollTo(newIndex, anchor: .leading)
                    }
                }
            }

            HStack(spacing: 16) {
                Button {
                    currentIndex = max(currentIndex - 1, 0)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(currentIndex == 0)

                Text("\(currentIndex + 1) / \(imageURLs.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)

                Button {
                    currentIndex = min(currentIndex + 1, imageURLs.count - 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(currentIndex == imageURLs.count - 1)
            }
        }
        .onChange(of: imageURLs.map { $0?.absoluteString }) { _, _ in
            currentIndex = 0
        }
    }
}
