import SwiftUI
import AuthenticationServices

struct AccountSettings: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var showSettings: Bool
    
    @ObservedObject private var userRepo = UserRepository.shared
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var ebayAuthService = EbayAuthService.shared
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    @State private var isConnecting = false
    @State private var isDisconnecting = false
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var isShowingError = false
    
    @State private var connectTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Account") {
                    LabeledContent("Email", value: auth.user?.email ?? "—")
                }

                Section {
                    LabeledContent("Status") {
                        if isDisconnecting {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Disconnecting…")
                                    .foregroundStyle(.secondary)
                            }
                        } else if userRepo.isEbayConnected {
                            HStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("Connected")
                                    .foregroundStyle(.secondary)
                                Button("Disconnect") {
                                    disconnectEbay()
                                }
                                .controlSize(.small)
                            }
                        } else if isConnecting {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Button("Cancel") {
                                    connectTask?.cancel()
                                }
                            }
                        } else {
                            Button("Connect…") {
                                connectEbay()
                            }
                            .controlSize(.small)
                        }
                    }
                } header: {
                    Text("eBay")
                } footer: {
                    if userRepo.isEbayConnected {
                        Text("Listr can list and update postcards on your eBay account. Disconnecting won’t end your existing listings.")
                    } else {
                        Text("Connect your eBay account so Listr can list postcards for you.")
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Sign Out") {
                    authVM.signOut()
                }
                Spacer()
                Button("Done") {
                    showSettings = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(width: 440)
        .alert(errorTitle, isPresented: $isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            connectTask?.cancel()
        }
    }

    private func showError(_ title: String, _ error: Error) {
        errorTitle = title
        errorMessage = error.localizedDescription
        isShowingError = true
    }

    private func connectEbay() {
        isConnecting = true

        connectTask = Task {
            defer {
                isConnecting = false
                connectTask = nil
            }
            
            do {
                try await ebayAuthService.connect(using: webAuthenticationSession)
            } catch ASWebAuthenticationSessionError.canceledLogin {
                // User closed the eBay window, not an error.
            } catch is CancellationError {
                // User clicked Cancel, not an error.
            } catch {
                showError("Couldn't Connect to eBay", error)
            }
        }
    }
    
    private func disconnectEbay() {
        isDisconnecting = true
        
        Task {
            defer {
                isDisconnecting = false
            }
            
            do {
                try await ebayAuthService.disconnect()
            } catch {
                showError("Couldn't Disconnect eBay", error)
            }
        }
    }
}
