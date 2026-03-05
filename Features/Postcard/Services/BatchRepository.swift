//
//  BatchRepository.swift
//  Listr
//
//  Created by Felix on 10/29/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class BatchRepository: ObservableObject {
    static let shared = BatchRepository()
    private init() {}
    
    private let db = Firestore.firestore()
    private let userID = "JWtpA1hS0PxKRyTKAtm5"
    
    var batchesCollection: CollectionReference {
        db.collection("users").document(userID).collection("batches")
    }
    
    @Published private(set) var cachedBatches: [PostcardBatch] = []
    
    private var listener: ListenerRegistration?
    
    func startListening() {
        stopListening()
        listener = batchesCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self, let snapshot else { return }
            
            let batches = snapshot.documents.compactMap { doc in
                try? doc.data(as: PostcardBatch.self)
            }
            
            Task { @MainActor in
                self.cachedBatches = batches
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func createNewBatchID() -> String {
        UUID().uuidString
    }
    
    func deleteBatch(_ batchID: String) async throws {
        try await batchesCollection
            .document(batchID)
            .delete()
    }
    
    func deletePostcard(_ postcard: PostcardDetails) async throws {
        let batchRef = batchesCollection.document(postcard.batchID)

        try await batchRef.updateData([
            "postcardIDs": FieldValue.arrayRemove([postcard.id!]),
            "count": FieldValue.increment(Int64(-1))
        ])

        let snapshot = try await batchRef.getDocument()
        guard let data = snapshot.data() else { return }

        if let count = data["count"] as? Int, count <= 0 {
            try await batchRef.delete()
            return
        }

        if let ids = data["postcardIDs"] as? [String], ids.isEmpty {
            try await batchRef.delete()
        }
    }
    
    func deletePostcards(_ postcards: [PostcardDetails]) async {
        let groups = Dictionary(grouping: postcards, by: { $0.batchID })
        
        for (batchID, items) in groups {
            let ids: [String] = items.compactMap { $0.id }
            guard !ids.isEmpty else { continue }
            let batchRef = batchesCollection.document(batchID)
            
            do {
                try await batchRef.updateData([
                    "postcardIDs": FieldValue.arrayRemove(ids),
                    "count": FieldValue.increment(Int64(-Int(ids.count)))
                ])
                
                let snapshot = try await batchRef.getDocument()
                if let data = snapshot.data() {
                    if let count = data["count"] as? Int, count <= 0 {
                        try await batchRef.delete()
                        continue
                    }
                    if let remaining = data["postcardIDs"] as? [String], remaining.isEmpty {
                        try await batchRef.delete()
                    }
                }
            } catch {
                // todo: popup
                print("Failed to update/delete batch \(batchID): \(error)")
            }
        }
    }
}

