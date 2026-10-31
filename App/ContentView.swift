import SwiftUI

// TODO: Charge users for postcard credits, 2.99 for 100 postcard scans, 4.99 for 200, etc... prices can be adjusted later. Give them 50 scans for free when signing up, hopefully they can't bypass it by creating multiple accounts. Maybe check if ebay account is already linked to another account? What if they forget their login... $0.34 for 100 postcard cost. So 1 postcard = 1/3rd of a cent

struct ContentView: View {
    @ObservedObject private var postcardRepo = PostcardRepository.shared
    @ObservedObject private var batchRepo = BatchRepository.shared
    @ObservedObject private var auth = AuthService.shared
    @StateObject private var controller = PostcardAnalysisController()
    private let client = EbayClient(tokenProvider: EnvironmentTokenProvider())

    @State private var filter: PostcardFilter = .all
    @State private var sortOrder = PostcardSortOrder()
    @State private var searchText = ""
    @State private var selectedPostcards: [PostcardDetails] = []
    @State private var showInspector = true
    @State private var showEbaySheet = false
    
    @State private var postcardsToDelete: [PostcardDetails] = []
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationSplitView {
            Sidebar(batchID: $filter.batchID, batches: batchRepo.batches, auth: auth)
                .navigationSplitViewColumnWidth(200)
        } detail: {
            PostcardCollection(postcards: visiblePostcards, selectedPostcards: $selectedPostcards, onDelete: requestDelete)
                .frame(minWidth: 500)
                .navigationTitle(title)
                .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
                .toolbar {
                    ToolbarItem {
                        Button {
                            showEbaySheet.toggle()
                        } label: {
                            Label("List on eBay", systemImage: "tag")
                        }
                        .disabled(!selectedPostcards.contains { $0.status == .readyToList })
                        .help("List selected Ready to List postcards on eBay")
                    }
                    
                    CollectionToolbar.importButton {
                        if auth.user != nil {
                            controller.openFolderPicker()
                        }
                    }
                    CollectionToolbar.filterButton(status: $filter.status)
                    CollectionToolbar.sortButton(sortOrder: $sortOrder)
                    CollectionToolbar.inspectorButton(showInspector: $showInspector)
                }
                .inspector(isPresented: $showInspector) {
                    PostcardInspector(
                        selectedPostcards: selectedPostcards,
                        onSave: savePostcard,
                        onListEbay: onListEbay,
                        onUpdateEbay: onUpdateEbay
                    )
                    .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
                }
        }
        .overlay { analysisOverlay }
        .sheet(isPresented: $showEbaySheet) {
            PublishToEbaySheet(postcards: selectedPostcards) { postcard in
                try await listPostcard(postcard)
            }
        }
        .animation(.snappy, value: controller.isAnalyzing)
        .onAppear {
            batchRepo.startListening()
            loadPostcards()
        }
        .onChange(of: filter) {
            selectedPostcards = []
            loadPostcards()
        }
        .onChange(of: sortOrder) {
            loadPostcards()
        }
        .onDeleteCommand {
            requestDelete(selectedPostcards)
        }
        .confirmationDialog(
            postcardsToDelete.count == 1 ? "Delete this postcard?" : "Delete \(postcardsToDelete.count) postcards?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await deletePostcards(postcardsToDelete)
                    } catch {
                        print("Error deleting postcards: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            let listedCount = postcardsToDelete.filter { $0.status == .listed }.count
            
            if listedCount > 0 {
                Text("\(listedCount) of these postcards are listed on eBay. Their listings will be ended.\nThis can't be undone.")
            } else {
                Text("This can't be undone.")
            }
        }
    }
    
    private func requestDelete(_ postcards: [PostcardDetails]) {
        guard !postcards.isEmpty else { return }
        showDeleteConfirmation = true
        postcardsToDelete = postcards
    }
    
    private func deletePostcards(_ postcards: [PostcardDetails]) async throws {
        var postcardsToDelete: [PostcardDetails] = []
        var firstError: Error?
        
        for postcard in postcards {
            if postcard.status == .listed {
                do {
                    try await client.deleteListing(postcard)
                } catch {
                    firstError = firstError ?? error
                    continue
                }
            }
            
            postcardsToDelete.append(postcard)
        }
        
        if !postcardsToDelete.isEmpty {
            try await postcardRepo.deletePostcards(postcardsToDelete)
        }
        
        selectedPostcards.removeAll { selected in
            postcardsToDelete.contains { $0.id == selected.id }
        }
        
        if let firstError {
            throw firstError
        }
    }
    
    private func savePostcard(_ postcard: PostcardDetails) async throws {
        try await postcardRepo.updatePostcard(postcard)
        replaceInSelection(postcard)
    }
    
    private func replaceInSelection(_ postcard: PostcardDetails) {
        if let index = selectedPostcards.firstIndex(where: { $0.id == postcard.id }) {
            selectedPostcards[index] = postcard
        }
    }
    
    private func onUpdateEbay() async throws {
        guard let postcard = selectedPostcards.first else { return }
        try await client.updateListing(postcard)
    }
    
    private func listPostcard(_ postcard: PostcardDetails) async throws {
        let listingId = try await client.createListing(postcard)
        
        var updatedPostcard = postcard
        updatedPostcard.markListed(listingId: listingId)
        
        try await postcardRepo.updatePostcard(updatedPostcard)
        replaceInSelection(updatedPostcard)
    }
    
    private func onListEbay() async throws {
        guard let postcard = selectedPostcards.first else { return }
        try await listPostcard(postcard)
    }

    private func loadPostcards() {
        postcardRepo.listen(to: filter, sortedBy: sortOrder)
    }

    private var title: String {
        let statusTitle = filter.status?.rawValue.capitalized ?? "All"
        guard let id = filter.batchID, let batch = batchRepo.batches.first(where: { $0.id == id }) else {
            return statusTitle
        }
        
        return "\(statusTitle) · \(batch.scannedAt.formatted(date: .abbreviated, time: .omitted))"
    }

    private var visiblePostcards: [PostcardSummary] {
        guard !searchText.isEmpty else { return postcardRepo.postcards }
        return postcardRepo.postcards.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    @ViewBuilder
    private var analysisOverlay: some View {
        if controller.isAnalyzing {
            AnalysisProgressPopup(
                analyzed: controller.postcardsAnalyzed,
                total: controller.totalPostcards,
                onCancel: { controller.cancelAnalysis() }
            )
            .transition(.opacity)
        }

        if let errorMessage = controller.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .padding()
        }
    }
}
