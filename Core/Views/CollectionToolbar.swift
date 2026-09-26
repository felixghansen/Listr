//
//  CollectionToolbar.swift
//  Listr
//
//  Created by Felix on 1/1/26.
//

import Foundation
import SwiftUI

enum CollectionToolbar {
    @ToolbarContentBuilder
    static func importButton(
        onImport: @escaping () -> Void
    ) -> some ToolbarContent {
        ToolbarItem {
            Button(action: onImport) {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .help("Import Postcards")
        }
    }

    @ToolbarContentBuilder
    static func inspectorButton(
        showInspector: Binding<Bool>
    ) -> some ToolbarContent {

        ToolbarItem {
            Button {
                showInspector.wrappedValue.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
            .help(showInspector.wrappedValue ? "Hide Inspector" : "Show Inspector")
        }
    }

    @ToolbarContentBuilder
    static func sortButton(sortOrder: Binding<PostcardSortOrder>) -> some ToolbarContent {
        ToolbarItem {
            Menu {
                Picker("Sort By", selection: sortOrder.field) {
                    ForEach(PostcardSortOrder.Field.allCases) { field in
                        Text(field.rawValue).tag(field)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()

                Divider()

                Picker("Order", selection: sortOrder.descending) {
                    Text("Ascending").tag(false)
                    Text("Descending").tag(true)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            .help("Sort Postcards")
        }
    }
}


