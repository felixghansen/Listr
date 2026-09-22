//
//  AuthEntry.swift
//  Listr
//
//  Created by Felix on 9/22/26.
//

import SwiftUI

struct AuthEntry: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var authService: AuthService
    @State var showVerification: Bool = false
    
    var body: some View {
        Group {
            if authVM.needsVerification {
                VerificationScreen()
                    .environmentObject(authVM)
            } else {
                AccountSignInAndRegistration()
                    .environmentObject(authVM)
            }
        }
        .frame(maxWidth: 600, maxHeight: 300)
        
    }
}
    
