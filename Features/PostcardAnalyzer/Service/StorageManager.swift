import Foundation
import FirebaseStorage

@MainActor
final class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage()
    
    private init() {}
    
    func uploadImageData(_ data: Data, batchID: String, fileName: String) async throws -> String {
        let storageRef = storage.reference().child(FirestorePaths.imagePath(batchID: batchID, fileName: fileName))
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    /// Deletes images by download URL. Missing files are ignored.
    func deleteImages(at urlStrings: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for urlString in urlStrings {
                group.addTask {
                    try? await Storage.storage().reference(forURL: urlString).delete()
                }
            }
        }
    }
}
