import SwiftUI
import AuthenticationServices

struct AccountSettings: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var showSettings: Bool

    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var ebayAuthService = EbayAuthService.shared
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    @State private var isConnecting = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var connectTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Account") {
                    LabeledContent("Email", value: auth.user?.email ?? "—")
                }

                Section {
                    LabeledContent("eBay Account") {
                        if ebayAuthService.isConnected {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("Connected")
                                    .foregroundStyle(.secondary)
                            }
                        } else if isConnecting {
                            HStack(spacing: 8) {
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
                        }
                    }
                } header: {
                    Text("eBay")
                } footer: {
                    Text("Connect your eBay account so Listr can list postcards for you.")
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
        .alert("Couldn't Connect to eBay", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            connectTask?.cancel()
        }
    }

    private func connectEbay() {
        isConnecting = true

        connectTask = Task {
            do {
                try await ebayAuthService.connect(using: webAuthenticationSession)
            } catch ASWebAuthenticationSessionError.canceledLogin {
                // User closed the eBay window, not an error.
            } catch is CancellationError {
                // User clicked Cancel, not an error.
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
            }

            isConnecting = false
            connectTask = nil
        }
    }
}
