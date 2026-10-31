//
//  UserRepository.swift
//  Listr
//
//  Created by Felix on 10/31/26.
//

import Foundation
import FirebaseFirestore

@MainActor
final class UserRepository: ObservableObject {
    static let shared = UserRepository()
    
    @Published private(set) var isEbayConnected = false
    private var listener: ListenerRegistration?
    
    private init() {}
    
    func startListening() {
        stopListening()
        listener = FirestorePaths.user().addSnapshotListener { [weak self] snapshot, error in
            if let error {
                print("User listener failed: \(error)")
                return
            }
            guard let snapshot else { return }
            
            self?.isEbayConnected = snapshot.get("isEbayConnected") as? Bool ?? false
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
        isEbayConnected = false
    }
}
