//
//  FirebaseAuth.swift
//  Listr
//
//  Created by Felix on 3/7/26.
//

import Foundation
import FirebaseAuth

final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    
    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }
    
    func updateDisplayName(to name: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else { return }
        
        let request = user.createProfileChangeRequest()
        request.displayName = name
        
        request.commitChanges { error in
            self.currentUser = Auth.auth().currentUser
            completion(error)
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
