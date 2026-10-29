//
//  PostcardImage.swift
//  Listr
//
//  Created by Felix on 10/31/25.
//

import Foundation
import SwiftUI
import QuickLook

enum ImageScale {
    case fit, fill
}

struct PostcardImage: View {
    let url: URL?
    let scaledTo: ImageScale
    var placeholderURL: URL? = nil

    @StateObject private var imageLoader = ImageLoader(url: nil)
    @StateObject private var placeholderLoader = ImageLoader(url: nil)

    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: scaledTo == .fill ? .fill : .fit)
            } else if let placeholder = placeholderLoader.image {
                Image(nsImage: placeholder)
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
            imageLoader.update(url: url)
            placeholderLoader.update(url: placeholderURL)
        }
        .onChange(of: url) { _, newURL in
            imageLoader.update(url: newURL)
        }
        .onChange(of: placeholderURL) { _, newURL in
            placeholderLoader.update(url: newURL)
        }
    }
}

struct ImageCarousel: View {
    let frontImageThumbnailURL: URL?
    let imageURLs: [URL?]

    private let aspectRatio: CGFloat = 3 / 2
    @State private var currentIndex = 0
    
    @State private var isDownloadingForQL: Bool = false
    @State private var localFileURL: URL? = nil

    var body: some View {
        VStack(spacing: 12) {
            ScrollViewReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                            PostcardImage(url: imageURL, scaledTo: .fit, placeholderURL: index == 0 ? frontImageThumbnailURL : nil)
                                .onTapGesture {
                                    triggerQuickLook()
                                }
                                .help("Click to enlarge")
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(index)
                        }
                    }
                }
                .aspectRatio(aspectRatio, contentMode: .fit)
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
        .quickLookPreview($localFileURL)
    }
    
    private func triggerQuickLook() {
        guard let remoteURL = imageURLs[currentIndex], !isDownloadingForQL else { return }
        isDownloadingForQL = true
        
        Task {
            do {
                let localURL = try await QuickLookService.prepareLocalURL(from: remoteURL)
                
                await MainActor.run {
                    self.localFileURL = localURL
                    self.isDownloadingForQL = false
                }
            } catch {
                print("Failed to stage image for Quick Look: \(error)")
                await MainActor.run {
                    self.isDownloadingForQL = false
                }
            }
        }
    }
}
