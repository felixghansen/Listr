import SwiftUI
import AppKit

enum Tab {
    case collection
    
    var title: String {
        switch self {
            case .collection: return "Collection"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .collection

    @StateObject private var controller = PostcardAnalysisController()
    @StateObject private var postcardRepo = PostcardRepository.shared
    @StateObject private var batchRepo = BatchRepository.shared
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    @State private var filter = PostcardFilter()
    @State private var searchText = ""
    
    @State private var selectedPostcards: [PostcardDetails] = []
    @State private var showInspector = true

    private var visiblePostcards: [PostcardSummary] {
        guard !searchText.isEmpty else {
            return postcardRepo.cachedSummaries
        }

        return postcardRepo.cachedSummaries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Navigation(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(150)
        } detail: {
            VStack {
                switch selectedTab {
                case .collection:
                    Collection(postcards: visiblePostcards, selectedPostcards: $selectedPostcards)
                }
            }
            .navigationTitle(selectedTab.title)
            .searchable(
                text: $searchText,
                placement: .sidebar,
                prompt: "Search"
            )
            .toolbar {
                CollectionToolbar.importButton(
                    onImport: { controller.openFolderPicker() }
                )
                CollectionToolbar.filterAndSortButtons(
                    filter: $filter
                )
                CollectionToolbar.inspectorButton(showInspector: $showInspector)
            }
            .inspector(isPresented: $showInspector) {
                PostcardInspector(selectedPostcards: $selectedPostcards)
                    .inspectorColumnWidth(min: 350, ideal: 400, max: 450)
            }
        }
        .overlay(alignment: .center) {
            if controller.isAnalyzing {
                let fraction = controller.totalImages > 0 ? Double(controller.imagesAnalyzed) / Double(controller.totalImages) : nil
                Popup(
                    style: .progress(fraction),
                    title: "Analyzing…",
                    message: "Analyzed \(controller.imagesAnalyzed)/\(controller.totalImages) images",
                    secondaryActionTitle: "Cancel",
                    secondaryAction: { controller.cancelAnalysis() }
                )
                .frame(maxWidth: 500)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .animation(.snappy, value: controller.isAnalyzing)
            }
        }
        .onAppear {
            postcardRepo.startListening(for: PostcardFilter())
            batchRepo.startListening()
        }
        .onChange(of: filter) { _, newFilter in
            postcardRepo.startListening(for: newFilter)
        }
    }
}

