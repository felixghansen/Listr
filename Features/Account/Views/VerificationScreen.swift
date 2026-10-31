//
//  VerificationScreen.swift
//  Listr
//
//  Created by Felix on 9/22/26.
//

import Foundation
import SwiftUI

struct VerificationScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        VStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 24))
                            .foregroundStyle(.blue)
                        
                        Text("Verify Your Email")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("We sent a verification link to your email. Click it to access Listr.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            
            VStack {
                HStack {
                    Button("Back") {
                        authVM.needsVerification = false
                    }
                    .font(.subheadline)
                    .disabled(authVM.isLoading)
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            authVM.sendVerification()
                        }) {
                            if authVM.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text(authVM.canResend ? "Resend Email" : "Resend (\(authVM.resendCooldown)s)")
                            }
                        }
                        .disabled(!authVM.canResend || authVM.isLoading)
                        .font(.caption)
                        
                        Button(action: {
                            authVM.checkVerification()
                        }) {
                            if authVM.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("I'm Verified")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(authVM.isLoading)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    VerificationScreen()
        .environmentObject(AuthViewModel())
}
