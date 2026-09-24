//
//  AccountSignInAndRegistration.swift
//  Listr
//
//  Created by Felix on 3/8/26.
//

import Foundation
import SwiftUI

struct AccountSignInAndRegistration: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isRegistering: Bool = false
    
    @State private var isHoveringForgotPassword = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack {
                 Text(isRegistering ? "Create Account" : "Sign In")
                     .font(.title2)
                     .fontWeight(.semibold)
                 
//                 Text(isRegistering
//                     ? "Get started by creating your account"
//                     : "Welcome back")
//                     .font(.subheadline)
//                     .foregroundColor(.secondary)
             }
            
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
                    .onSubmit {
                        if isRegistering {
                            authVM.register(email: email, password: password, name: name)
                        } else {
                            authVM.signIn(email: email, password: password)
                        }
                    }
                } footer: {
                    if !isRegistering {
                        HStack {
//                            Spacer()
                            
                            Button("Forgot Password?") {}
                                .buttonStyle(.link)
                                .foregroundStyle(.secondary)
                        }
                        
                    }
                }
            }
            
            VStack {
                HStack {
                    Button(isRegistering ? "Already have an account?" : "Don't have an account?") {
                        withAnimation {
                            isRegistering.toggle()
                        }
                    }
                    .font(.subheadline)
                    .disabled(authVM.isLoading)
                    
                    Spacer()
                    
                    HStack {
                        
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
        .padding(.all, 24)
    }
}

#Preview {
    AccountSignInAndRegistration()
        .environmentObject(AuthViewModel())
}
