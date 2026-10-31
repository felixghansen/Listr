//
//  FirestorePaths.swift
//  Listr
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FirestorePaths {
    static var currentUserID: String {
        guard let uid = Auth.auth().currentUser?.uid else {
            fatalError("Firestore accessed without a signed-in user")
        }
        return uid
    }

    static func user(_ uid: String = currentUserID) -> DocumentReference {
        Firestore.firestore().collection("users").document(uid)
    }

    static func postcards(_ uid: String = currentUserID) -> CollectionReference {
        user(uid).collection("postcards")
    }

    static func batches(_ uid: String = currentUserID) -> CollectionReference {
        user(uid).collection("batches")
    }

    /// Storage path for an uploaded postcard image.
    static func imagePath(batchID: String, fileName: String, uid: String = currentUserID) -> String {
        "users/\(uid)/batches/\(batchID)/\(fileName)"
    }
}
