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
    @EnvironmentObject var coordinator: AccountSettingsCoordinator
    
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
