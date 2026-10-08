import SwiftUI

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
                    PostcardInspector(selectedPostcards: $selectedPostcards)
                        .inspectorColumnWidth(350)
                }
        }
        .overlay { analysisOverlay }
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
            Popup(
                style: .progress(analysisProgress),
                title: "Analyzing…",
                message: "Analyzed \(controller.imagesAnalyzed)/\(controller.totalImages) images",
                secondaryActionTitle: "Cancel",
                secondaryAction: { controller.cancelAnalysis() }
            )
            .frame(maxWidth: 500)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
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
