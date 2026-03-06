//
//  PostcardRepository.swift
//  Listr
//
//  Created by Felix on 10/21/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class PostcardRepository: ObservableObject {
    static let shared = PostcardRepository()
    private init() {}
    
    private let db = Firestore.firestore()
    private let userID: String = config.userID // TODO
    private let pageSize = 50
    
    private var postcardsCollection: CollectionReference {
        db.collection("users").document(userID).collection("postcards")
    }
    
    @Published private(set) var cachedSummaries: [PostcardSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMorePages = true

    // Cache full details for the current page only
    private var cachedDetails: [String: PostcardDetails] = [:]
    
    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    
    func startListening(for filter: PostcardFilter) {
        stopListening()
        resetPagination()
        
        let query = makeQuery(for: filter).limit(to: pageSize)
        
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self, let snapshot else { return }
            
            let details = snapshot.documents.compactMap { try? $0.data(as: PostcardDetails.self) }
            let summaries = details.map { PostcardSummary(from: $0) }
            
            Task { @MainActor in
                self.cachedSummaries = summaries
                self.lastDocument = snapshot.documents.last
                self.hasMorePages = snapshot.documents.count >= self.pageSize
                
                // Clear details cache when a new query/page 1 is loaded
                self.cachedDetails.removeAll()
                // Warm details for the current page
                await self.warmDetails(for: summaries)
                
                await self.preloadImages(for: summaries)
            }
        }

    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func loadNextPage(for filter: PostcardFilter) async throws {
        guard hasMorePages, !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        var query = makeQuery(for: filter).limit(to: pageSize)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        
        guard !snapshot.isEmpty else {
            hasMorePages = false
            return
        }
        
        let details = snapshot.documents.compactMap { try? $0.data(as: PostcardDetails.self) }
        let summaries = details.map { PostcardSummary(from: $0) }
        
        // Switching to next page: clear previous page's warmed details
        cachedDetails.removeAll()
        // Warm details for this page (the newly fetched summaries only)
        await warmDetails(for: summaries)
        
        cachedSummaries.append(contentsOf: summaries)
        lastDocument = snapshot.documents.last
        hasMorePages = snapshot.documents.count == pageSize
    }
    
    func resetPagination() {
        cachedSummaries = []
        lastDocument = nil
        hasMorePages = true
        isLoading = false
        cachedDetails.removeAll()
    }
    
    private func preloadImages(for summaries: [PostcardSummary]) async {
        await withTaskGroup(of: Void.self) { group in
            for summary in summaries {
                if let frontURL = summary.frontImageURL {
                    group.addTask { await self.preloadImage(url: frontURL) }
                }
                if let backURL = summary.backImageURL {
                    group.addTask { await self.preloadImage(url: backURL) }
                }
            }
        }
    }

    private func preloadImage(url: URL) async {
        if await ImageCache.shared.data(for: url) != nil { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await ImageCache.shared.insert(data, for: url)
        } catch {
            print("Preload failed for \(url):", error)
        }
    }
    
    func savePostcards(_ postcards: [PostcardDetails], toBatch batchID: String) async throws {
        let batchRef = BatchRepository.shared.batchesCollection.document(batchID)
        var postcardIDs: [String] = []
        
        for postcard in postcards {
            let docRef = postcardsCollection.document()
            try docRef.setData(from: postcard)
            postcardIDs.append(docRef.documentID)
        }
        
        try await batchRef.setData([ // THIS MUST MATCH POSTCARDBATCH MODEL
            "scannedAt": Timestamp(date: Date()),
            "count": FieldValue.increment(Int64(postcards.count)),
            "postcardIDs": FieldValue.arrayUnion(postcardIDs)
        ], merge: true)
    }
    
    func updatePostcard(_ postcard: PostcardDetails) async throws {
        guard let id = postcard.id else {
            assertionFailure("Cannot update postcard without ID")
            return
        }

        try postcardsCollection
            .document(id)
            .setData(from: postcard, merge: true)
        
        cachedDetails[id] = postcard
        if let index = cachedSummaries.firstIndex(where: { $0.id == id }) {
            cachedSummaries[index] = PostcardSummary(from: postcard)
        }
    }
    
    func deletePostcard(_ postcard: PostcardDetails) async throws {
        guard let id = postcard.id else {
            assertionFailure("Cannot update postcard without ID")
            return
        }
        
        try await postcardsCollection
            .document(id)
            .delete()
        
        cachedDetails.removeValue(forKey: id)
        cachedSummaries.removeAll { $0.id == id }
        
        try await BatchRepository.shared.deletePostcard(postcard)
    }

    func deletePostcards(_ postcards: [PostcardDetails]) async throws {
        let batch = db.batch()
        for p in postcards {
            guard let id = p.id else { continue }
            batch.deleteDocument(postcardsCollection.document(id))
        }
        try await batch.commit()
        
        for p in postcards {
            if let id = p.id {
                cachedDetails.removeValue(forKey: id)
            }
        }
        cachedSummaries.removeAll { summary in postcards.contains { $0.id == summary.id } }
        
        await BatchRepository.shared.deletePostcards(postcards)
    }
     
    func getPostcardDetails(id: String) async throws -> PostcardDetails {
        if let cached = cachedDetails[id] { return cached }
        let doc = try await postcardsCollection.document(id).getDocument()
        let details = try doc.data(as: PostcardDetails.self)
        cachedDetails[id] = details
        return details
    }
    
    private func warmDetails(for summaries: [PostcardSummary]) async {
        await withTaskGroup(of: Void.self) { group in
            for summary in summaries {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let id = summary.id
                    if await self.cachedDetails[id] != nil { return }
                    do {
                        let details = try await self.getPostcardDetails(id: id)
                        await MainActor.run {
                            self.cachedDetails[id] = details
                        }
                    } catch { }
                }
            }
        }
    }
    
    private func makeQuery(for filter: PostcardFilter) -> Query {
        var query: Query = postcardsCollection
        
        if let status = filter.status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        
        switch filter.batchFilter {
            case .selected:
                query = query.whereField("batchID", in: Array(filter.batchFilter.batchIDs))
            case .none:
                break
        }
        
        switch filter.sortOrder {
            case .scannedAt(let descending):
                query = query.order(by: "scannedAt", descending: descending)
            case .price(let descending):
                query = query.order(by: "aiData.suggestedPriceCAD.price", descending: descending)
        }
        
        return query
    }
}

