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
    
    var body: some View {
        VStack {
            Text("Settings")
            Button("Done") {
                coordinator.hideAccountSettings()
            }
        }
    }
}
