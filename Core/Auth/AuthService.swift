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
    
    @Published var user: User?
    
    private init() {
        user = Auth.auth().currentUser
        
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    func refreshVerificationStatus(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "AuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active session found."])
            completion(.failure(error))
            return
        }
        
        user.reload { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.user = Auth.auth().currentUser
                completion(.success(()))
            }
        }
    }
    
    func loginUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let user = Auth.auth().currentUser, !user.isEmailVerified {
                    self.sendVerification(completion: completion)
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func registerUser(email: String, password: String, name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.updateDisplayName(to: name) { nameResult in
                switch nameResult {
                case .success:
                    self.sendVerification(completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func sendVerification(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "AuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active session found."])
            completion(.failure(error))
            return
        }
        
        user.sendEmailVerification { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateDisplayName(to name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "AuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active session found."])
            completion(.failure(error))
            return
        }
        
        let request = user.createProfileChangeRequest()
        request.displayName = name
        
        request.commitChanges { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.user = Auth.auth().currentUser
                completion(.success(()))
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}

