import Foundation
import FirebaseStorage
import AppKit
import FirebaseAuth

@MainActor
final class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage()
    
    private var userID: String {
        guard let uid = Auth.auth().currentUser?.uid else {
            fatalError("StorageManager accessed without authentication")
        }
        return uid
    }
    
    private init() {}
    
    func uploadImageData(_ data: Data, batchID: String, fileName: String) async throws -> String {
        let path = "users/\(userID)/batches/\(batchID)/\(fileName)"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
    
    
}
