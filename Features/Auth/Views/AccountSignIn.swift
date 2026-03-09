//
//  AccountSignIn.swift
//  Listr
//
//  Created by Felix on 3/8/26.
//

import Foundation
import SwiftUI

struct AccountSignIn: View {
    @ObservedObject var coordinator: AccountSettingsCoordinator
    @ObservedObject var authVM: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isRegistering: Bool = false
    
    var body: some View {
        VStack {
            Form {
                Section {
                    if isRegistering {
                        TextField(text: $name, prompt: Text("Required")) {
                            Text("Name")
                        }
                        .textContentType(.name)
                        .autocorrectionDisabled()
                    }
                    
                    TextField(text: $email, prompt: Text("Required")) {
                        Text("Email")
                    }
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    
                    SecureField(text: $password, prompt: Text("Required")) {
                        Text("Password")
                    }
                    .textContentType(isRegistering ? .newPassword : .password)
                    .autocorrectionDisabled()
                } footer: {
                    if !isRegistering {
                        Button("Forgot Password?") {
                            authVM.resetPassword(email: email)
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }
                }
            }
            
            VStack {
                HStack {
                    Button(isRegistering ? "Already have an account?" : "Create Account") {
                        withAnimation {
                            isRegistering.toggle()
                        }
                    }
                    .font(.subheadline)
                    .disabled(authVM.isLoading)
                    
                    Spacer()
                    
                    HStack {
                        Button("Cancel") {
                            coordinator.hideAccountSignIn()
                        }
                        .disabled(authVM.isLoading)
                        
                        Button(action: {
                            if isRegistering {
                                authVM.register(email: email, password: password, name: name)
                            } else {
                                authVM.signIn(email: email, password: password)
                            }
                        }) {
                            if authVM.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text(isRegistering ? "Register" : "Sign In")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                    }
                }
            }
        }
        .padding()
        .alert("Account", isPresented: $authVM.showAlert) {
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
    }
}
