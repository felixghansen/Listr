//
//  AccountSettingsCoordinator.swift
//  Listr
//
//  Created by Felix on 3/7/26.
//

import Foundation

class AccountSettingsCoordinator: ObservableObject {
    @Published var isShowingAccount = false
    
    func showAccountSettings() {
        isShowingAccount = true
    }
    
    func hideAccountSettings() {
        isShowingAccount = false
    }
    
    func handleDismiss() {
        // TODO
    }
}
