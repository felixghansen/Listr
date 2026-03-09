//
//  Settings.swift
//  Listr
//
//  Created by Felix on 3/7/26.
//

import Foundation
import SwiftUI

struct AccountSettings: View {
    @ObservedObject var coordinator: AccountSettingsCoordinator
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        VStack {
            Text("Account")
                .font(.headline)
            
            HStack {
                Spacer()
                Button("Sign out") {
                    authVM.signOut()
                }
                Button("Done") {
                    coordinator.hideAccountSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
