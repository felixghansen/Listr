import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class PostcardRepository: ObservableObject {
    static let shared = PostcardRepository()
    private init() {}

    @Published private(set) var postcards: [PostcardSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMorePages = true

    private let db = Firestore.firestore()
    private let pageSize = 50

    private var listener: ListenerRegistration?
    private var currentQuery: Query?
    private var lastDocument: DocumentSnapshot?
    private var detailsCache: [String: PostcardDetails] = [:]

    var postcardsCollection: CollectionReference {
        guard let userID = Auth.auth().currentUser?.uid else {
            fatalError("PostcardRepository accessed without authentication")
        }
        return db.collection("users").document(userID).collection("postcards")
    }

    // MARK: - Loading

    func listen(to item: SidebarItem, sortedBy sortOrder: PostcardSortOrder) {
        stopListening()
        postcards = []
        detailsCache = [:]
        lastDocument = nil
        hasMorePages = true

        let query = makeQuery(for: item, sortedBy: sortOrder)
        currentQuery = query

        listener = query.limit(to: pageSize).addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
            guard let snapshot = snapshot else { return }
            let details = snapshot.documents.compactMap { try? $0.data(as: PostcardDetails.self) }

            Task { @MainActor in
                guard let self else { return }
                self.cache(details)
                self.postcards = details.map(PostcardSummary.init(from:))
                self.lastDocument = snapshot.documents.last
                self.hasMorePages = snapshot.documents.count == self.pageSize
                await self.preloadImages(for: self.postcards)
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func loadNextPage() async throws {
        guard hasMorePages, !isLoading, let currentQuery else { return }

        isLoading = true
        defer { isLoading = false }

        var query = currentQuery.limit(to: pageSize)
        if let lastDocument {
            query = query.start(afterDocument: lastDocument)
        }

        let snapshot = try await query.getDocuments()
        let details = snapshot.documents.compactMap { try? $0.data(as: PostcardDetails.self) }
        let newPostcards = details.map(PostcardSummary.init(from:))

        cache(details)
        postcards.append(contentsOf: newPostcards)
        lastDocument = snapshot.documents.last ?? lastDocument
        hasMorePages = snapshot.documents.count == pageSize

        await preloadImages(for: newPostcards)
    }

    func details(for id: String) async throws -> PostcardDetails {
        if let cached = detailsCache[id] {
            return cached
        }
        let details = try await postcardsCollection.document(id).getDocument(as: PostcardDetails.self)
        detailsCache[id] = details
        return details
    }

    // MARK: - Saving and deleting

    func savePostcards(_ newPostcards: [PostcardDetails], toBatch batchID: String) async throws {
        var postcardIDs: [String] = []

        for postcard in newPostcards {
            let document = postcardsCollection.document()
            try document.setData(from: postcard)
            postcardIDs.append(document.documentID)
        }

        // Must match the PostcardBatch model
        try await BatchRepository.shared.batchesCollection.document(batchID).setData([
            "scannedAt": Timestamp(date: Date()),
            "count": FieldValue.increment(Int64(newPostcards.count)),
            "postcardIDs": FieldValue.arrayUnion(postcardIDs)
        ], merge: true)
    }

    func updatePostcard(_ postcard: PostcardDetails) async throws {
        guard let id = postcard.id else { return }

        try postcardsCollection.document(id).setData(from: postcard, merge: true)

        detailsCache[id] = postcard
        if let index = postcards.firstIndex(where: { $0.id == id }) {
            postcards[index] = PostcardSummary(from: postcard)
        }
    }

    func deletePostcard(_ postcard: PostcardDetails) async throws {
        guard let id = postcard.id else { return }

        try await postcardsCollection.document(id).delete()
        removeFromCache(ids: [id])

        try await BatchRepository.shared.deletePostcard(postcard)
    }

    func deletePostcards(_ postcardsToDelete: [PostcardDetails]) async throws {
        let ids = postcardsToDelete.compactMap(\.id)
        
        // atomic commit
        let deleteBatch = db.batch()
        for id in ids {
            deleteBatch.deleteDocument(postcardsCollection.document(id))
        }
        try await deleteBatch.commit()
        removeFromCache(ids: Set(ids))

        await BatchRepository.shared.deletePostcards(postcardsToDelete)
    }

    // MARK: - Helpers

    private func makeQuery(for item: SidebarItem, sortedBy sortOrder: PostcardSortOrder) -> Query {
        var query: Query = postcardsCollection

        switch item {
        case .all:
            break
        case .status(let status):
            query = query.whereField("status", isEqualTo: status.rawValue)
        case .batch(let id):
            query = query.whereField("batchID", isEqualTo: id)
        }

        let sortField: String
        switch sortOrder.field {
        case .dateScanned:
            sortField = "scannedAt"
        case .price:
            sortField = "aiData.suggestedPriceCAD.price"
        }
        query = query.order(by: sortField, descending: sortOrder.descending)

        return query
    }

    private func cache(_ details: [PostcardDetails]) {
        for postcard in details {
            if let id = postcard.id {
                detailsCache[id] = postcard
            }
        }
    }

    private func removeFromCache(ids: Set<String>) {
        for id in ids {
            detailsCache[id] = nil
        }
        postcards.removeAll { ids.contains($0.id) }
    }

    private func preloadImages(for summaries: [PostcardSummary]) async {
        let urls = summaries.flatMap { [$0.frontImageURL, $0.backImageURL] }.compactMap { $0 }

        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { await Self.preloadImage(url: url) }
            }
        }
    }

    // doesn't need to run on main actor
    private nonisolated static func preloadImage(url: URL) async {
        if await ImageCache.shared.data(for: url) != nil { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await ImageCache.shared.insert(data, for: url)
        } catch {
            print("Image preload failed for \(url): \(error)")
        }
    }
}

