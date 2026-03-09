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
    
    @ObservedObject private var postcardRepo = PostcardRepository.shared
    @ObservedObject private var batchRepo = BatchRepository.shared
    @ObservedObject private var auth = AuthService.shared
    
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var coordinator: AccountSettingsCoordinator
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

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
            Sidebar(selectedTab: $selectedTab, auth: auth)
                .navigationSplitViewColumnWidth(200)
        } detail: {
            VStack {
                switch selectedTab {
                case .collection:
                    Collection(postcards: visiblePostcards, selectedPostcards: $selectedPostcards, postcardRepository: postcardRepo)
                }
            }
            .frame(minWidth: 500)
            .navigationTitle(selectedTab.title)
            .searchable(
                text: $searchText,
                placement: .sidebar,
                prompt: "Search"
            )
            .toolbar {
                CollectionToolbar.importButton(
                    onImport: {
                        if let user = auth.user, user.isEmailVerified {
                            controller.openFolderPicker()
                        } else {
                            authVM.sendVerification()
                        }
                    }
                )
                CollectionToolbar.filterAndSortButtons(
                    filter: $filter
                )
                CollectionToolbar.inspectorButton(showInspector: $showInspector)
            }
            .inspector(isPresented: $showInspector) {
                PostcardInspector(selectedPostcards: $selectedPostcards)
                    .inspectorColumnWidth(350)
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
        .alert("Account", isPresented: $authVM.showAlert) {
            if authVM.alertState == .registrationSuccess || authVM.alertState == .unverifiedAction {
                Button(authVM.canResend ? "Resend Verification" : "Wait (\(authVM.resendCooldown)s)") {
                    authVM.sendVerification()
                }
                .disabled(!authVM.canResend)
            }
            Button("OK", role: .cancel) {
                switch authVM.alertState {
                case .registrationSuccess, .loginSuccess:
                    coordinator.hideAccountSignIn()
                default:
                    break
                }
            }
        } message: {
            Text(authVM.alertState.message)
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

