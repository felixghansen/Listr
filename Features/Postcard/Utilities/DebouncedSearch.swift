//
//  DebouncedSearch.swift
//  Listr
//
//  Created by Felix on 10/30/25.
//

import Foundation
import Combine

class DebouncedSearch: ObservableObject {
    static let shared = DebouncedSearch()
    
    private var cancellable: AnyCancellable?
    private let subject = PassthroughSubject<String, Never>()
    
    private init() {}
    
    func search(_ text: String, delay: TimeInterval = 0.3, completion: @escaping (String) -> Void) {
        // Cancel previous debounce
        cancellable?.cancel()
        
        // Create new debounced publisher
        cancellable = subject
            .debounce(for: .seconds(delay), scheduler: DispatchQueue.main)
            .sink { debouncedText in
                completion(debouncedText)
            }
        
        // Send the new value
        subject.send(text)
    }
}
