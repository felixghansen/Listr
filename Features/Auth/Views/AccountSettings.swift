//
//  Settings.swift
//  Listr
//
//  Created by Felix on 3/7/26.
//

import Foundation
import SwiftUI

struct AccountSettings: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack {
            Text("Account")
                .font(.headline)
            
            HStack { // TODO delete account button
                Spacer()
                Button("Sign out") {
                    authVM.signOut()
                }
                Button("Done") { // "Close"?
                    showSettings = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
