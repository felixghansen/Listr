//
//  AccountSettings.swift
//  Listr
//
//  Created by Felix on 3/7/26.
//

import SwiftUI
import AuthenticationServices

struct AccountSettings: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var showSettings: Bool
    
    @ObservedObject private var ebayAuthService = EbayAuthService.shared
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    
    @State private var isConnecting = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var connectTask: Task<Void, Never>?
    
    var body: some View {
        VStack {
            Text("Account")
                .font(.headline)
            
            HStack {
                Spacer()
                if ebayAuthService.isConnected {
                    Label("eBay Connected", systemImage: "checkmark.circle.fill")
                } else {
                    Button(isConnecting ? "Connecting…" : "Connect eBay Account") {
                        connectEbay()
                    }
                    .disabled(isConnecting)
                }
                if isConnecting {
                    Button("Cancel") {
                        connectTask?.cancel()
                    }
                }
                Button("Sign Out") {
                    authVM.signOut()
                }
                Button("Done") {
                    showSettings = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .alert("Couldn't connect to eBay", isPresented: $showAlert) {
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
                // user closed the ebay authentication window
            } catch is CancellationError {
                // user clicked the cancel button
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
            }
            
            isConnecting = false
            connectTask = nil
        }
    }
}
