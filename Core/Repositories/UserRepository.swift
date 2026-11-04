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
    
    private var userListener: ListenerRegistration?
    private var defaultsListener: ListenerRegistration?
    
    @Published private(set) var isEbayConnected = false
    @Published private(set) var listingDefaults: ListingDefaults?
    
    var ebayUnavailableReason: String? {
        if !isEbayConnected {
            return "Connect eBay in Account Settings to list postcards"
        }
        if listingDefaults?.isComplete != true {
            return "Choose your listing defaults in Account Settings to list postcards"
        }
        return nil
    }
    
    private init() {}
    
    func startListening() {
        stopListening()
        
        userListener = FirestorePaths.user().addSnapshotListener { [weak self] snapshot, error in
            if let error {
                print("User listener failed: \(error)")
                return
            }
            
            guard let snapshot else { return }
            
            self?.isEbayConnected = snapshot.get("isEbayConnected") as? Bool ?? false
        }
    
        defaultsListener = FirestorePaths.listingDefaults().addSnapshotListener { [weak self] snapshot, error in
            if let error {
                print("Listing defaults listener failed: \(error)")
                return
            }
            
            guard let snapshot else { return }
            
            self?.listingDefaults = try? snapshot.data(as: ListingDefaults.self)
        }
    }
    
    func stopListening() {
        userListener?.remove()
        userListener = nil
        
        defaultsListener?.remove()
        defaultsListener = nil
        
        listingDefaults = nil
        isEbayConnected = false
    }
    
    func saveDefaults(_ defaults: ListingDefaults) async throws {
        let encoded = try Firestore.Encoder().encode(defaults)
        
        try await FirestorePaths.listingDefaults().setData(encoded)
        
        listingDefaults = defaults
    }
}
