import Foundation
import FirebaseStorage
import AppKit

@MainActor
final class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage()
    private let userID: String = "JWtpA1hS0PxKRyTKAtm5"
    
    private init() {}
    
    func uploadImage(_ image: NSImage, batchID: String, fileName: String) async throws -> String {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [:]) else {
            throw NSError(domain: "UploadError", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to convert NSImage to JPEG data"])
        }

        let path = "users/\(userID)/batches/\(batchID)/\(fileName)"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
    
    
}
