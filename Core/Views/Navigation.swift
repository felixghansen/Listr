//
//  Navigation.swift
//  Listr
//
//  Created by Felix on 10/18/25.
//

import Foundation
import SwiftUI

struct Navigation: View {
    @Binding var selectedTab: Tab

    var body: some View {
        List(selection: $selectedTab) {
            NavigationLink(value: Tab.collection) {
                Label("Collection", systemImage: "square.grid.2x2")
            }
        }
        .padding(.vertical)
        .listStyle(.sidebar)
        .scrollDisabled(true)
    }
}

