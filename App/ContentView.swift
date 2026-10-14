import SwiftUI

// TODO: Charge users for postcard credits, 2.99 for 100 postcard scans, 4.99 for 200, etc... prices can be adjusted later. Give them 50 scans for free when signing up, hopefully they can't bypass it by creating multiple accounts. Maybe check if ebay account is already linked to another account? What if they forget their login... $0.34 for 100 postcard cost. So 1 postcard = 1/3rd of a cent

struct ContentView: View {
    @ObservedObject private var postcardRepo = PostcardRepository.shared
    @ObservedObject private var batchRepo = BatchRepository.shared
    @ObservedObject private var auth = AuthService.shared
    @StateObject private var controller = PostcardAnalysisController()

    @State private var filter: PostcardFilter = .all
    @State private var sortOrder = PostcardSortOrder()
    @State private var searchText = ""
    @State private var selectedPostcards: [PostcardDetails] = []
    @State private var showInspector = true
    @State private var showEbaySheet = false

    var body: some View {
        NavigationSplitView {
            Sidebar(batchID: $filter.batchID, batches: batchRepo.batches, auth: auth)
                .navigationSplitViewColumnWidth(200)
        } detail: {
            PostcardCollection(postcards: visiblePostcards, selectedPostcards: $selectedPostcards)
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
                    PostcardInspector(selectedPostcards: $selectedPostcards, onListEbay: {
                        showEbaySheet = true
                    })
                        .inspectorColumnWidth(350)
                }
        }
        .overlay { analysisOverlay }
        .sheet(isPresented: $showEbaySheet) {
            PublishToEbaySheet(postcards: selectedPostcards)
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
                analyzed: controller.imagesAnalyzed,
                total: controller.totalImages,
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

    private var analysisProgress: Double? {
        guard controller.totalImages > 0 else { return nil }
        return Double(controller.imagesAnalyzed) / Double(controller.totalImages)
    }
}
