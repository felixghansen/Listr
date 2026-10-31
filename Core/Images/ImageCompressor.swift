//
//  ImageCompressor.swift
//  Listr
//
//  Created by Felix on 10/29/26.
//

import AppKit
import ImageIO

enum ImageCompressor {
    static func jpegData(from url: URL, maxPixelSize: Int, quality: CGFloat) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }
}
