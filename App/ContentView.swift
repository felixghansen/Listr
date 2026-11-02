import SwiftUI

// TODO: Charge users for postcard credits, 2.99 for 100 postcard scans, 4.99 for 200, etc... prices can be adjusted later. Give them 50 scans for free when signing up, hopefully they can't bypass it by creating multiple accounts. Maybe check if ebay account is already linked to another account? What if they forget their login... $0.34 for 100 postcard cost. So 1 postcard = 1/3rd of a cent

struct ContentView: View {
    // In order to redraw this view when postcards load
    @ObservedObject private var postcardRepo = PostcardRepository.shared
    @ObservedObject private var batchRepo = BatchRepository.shared
    @ObservedObject private var userRepo = UserRepository.shared
    
    @ObservedObject private var auth = AuthService.shared
    @StateObject private var controller = PostcardAnalysisController()
    
    @StateObject private var viewModel = PostcardCollectionViewModel(
        ebayClient: EbayClient(tokenProvider: CloudFunctionTokenProvider())
    )

    @State private var showInspector = true
    @State private var showEbaySheet = false
    
    @State private var postcardsToDelete: [PostcardDetails] = []
    @State private var showDeleteConfirmation = false
    
    @State private var showDeleteError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            postcardCollection
        }
        .overlay { analysisOverlay }
        .sheet(isPresented: $showEbaySheet) {
            PublishToEbaySheet(postcards: viewModel.selectedPostcards) { postcard in
                try await viewModel.listPostcard(postcard)
            }
        }
        .animation(.snappy, value: controller.isAnalyzing)
        .onAppear {
            userRepo.startListening()
            batchRepo.startListening()
            viewModel.startListening()
        }
        .onDisappear {
            userRepo.stopListening()
            batchRepo.stopListening()
            viewModel.stopListening()
        }
        .onChange(of: viewModel.filter) {
            viewModel.selectedPostcards = []
            viewModel.startListening()
        }
        .onChange(of: viewModel.sortOrder) {
            viewModel.startListening()
        }
        .onDeleteCommand {
            requestDelete(viewModel.selectedPostcards)
        }
        .confirmationDialog(
            postcardsToDelete.count == 1 ? "Delete this postcard?" : "Delete \(postcardsToDelete.count) postcards?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deletePostcards(postcardsToDelete)
                    } catch {
                        errorMessage = error.localizedDescription
                        showDeleteError = true
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
        .alert("Couldn't Delete Some Postcards", isPresented: $showDeleteError) {
            Button("OK", role: .destructive) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private var sidebar: some View {
        Sidebar(batchID: $viewModel.filter.batchID, batches: batchRepo.batches, auth: auth)
            .navigationSplitViewColumnWidth(200)
    }
    
    private var postcardCollection: some View {
        PostcardCollection(
            postcards: viewModel.visiblePostcards,
            selectedPostcards: $viewModel.selectedPostcards,
            onDelete: requestDelete,
            onReachEnd: viewModel.loadNextPage
        )
        .frame(minWidth: 500)
        .navigationTitle(title)
        .searchable(text: $viewModel.searchText, placement: .sidebar, prompt: "Search")
        .toolbar { toolbar }
        .inspector(isPresented: $showInspector) {
            PostcardInspector(
                selectedPostcards: viewModel.selectedPostcards,
                isEbayConnected: userRepo.isEbayConnected,
                onSave: { postcard in
                    try await viewModel.savePostcard(postcard)
                },
                onListEbay: { postcard in
                    try await viewModel.listPostcard(postcard)
                },
                onUpdateEbay: { postcard in
                    try await viewModel.updateListing(postcard)
                }
            )
            .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem {
            Button {
                showEbaySheet.toggle()
            } label: {
                Label("List on eBay", systemImage: "tag")
            }
            .disabled(!userRepo.isEbayConnected || !viewModel.selectedPostcards.contains { $0.status == .readyToList })
            .help(userRepo.isEbayConnected
                ? "List selected Ready to List postcards on eBay"
                : "Connect eBay in Account Settings to list postcards"
            )
        }
        
        CollectionToolbar.importButton {
            if auth.user != nil {
                controller.openFolderPicker()
            }
        }
        CollectionToolbar.filterButton(status: $viewModel.filter.status)
        CollectionToolbar.sortButton(sortOrder: $viewModel.sortOrder)
        CollectionToolbar.inspectorButton(showInspector: $showInspector)
    }
    
    private func requestDelete(_ postcards: [PostcardDetails]) {
        guard !postcards.isEmpty else { return }
        showDeleteConfirmation = true
        postcardsToDelete = postcards
    }

    private var title: String {
        let statusTitle = viewModel.filter.status?.rawValue.capitalized ?? "All"
        guard let id = viewModel.filter.batchID, let batch = batchRepo.batches.first(where: { $0.id == id }) else {
            return statusTitle
        }
        
        return "\(statusTitle) · \(batch.scannedAt.formatted(date: .abbreviated, time: .omitted))"
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
