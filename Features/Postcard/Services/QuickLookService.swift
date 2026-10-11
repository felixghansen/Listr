//
//  QuickLookService.swift
//  Listr
//
//  Created by Felix on 10/9/26.
//

import Foundation

struct QuickLookService {
    static func prepareLocalURL(from remoteURL: URL) async throws -> URL {
        // 1. Download the remote data
        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // 2. Generate a secure temporary path matching the extension
        let ext = remoteURL.pathExtension.isEmpty ? "jpg" : remoteURL.pathExtension
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)

        // 3. Write data to the temp directory
        try data.write(to: tempURL)
        
        return tempURL
    }
}
