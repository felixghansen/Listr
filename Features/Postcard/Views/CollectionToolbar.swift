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
    static func filterButton(status: Binding<PostcardStatus?>) -> some ToolbarContent {
        ToolbarItem {
            Menu {
                Picker("Filter", selection: status) {
                    Label("All Postcards", systemImage: "square.grid.3x3.fill")
                        .tag(PostcardStatus?.none)

                    Divider()

                    ForEach(PostcardStatus.allCases, id: \.self) { option in
                        Label {
                            Text(option.rawValue.capitalized)
                        } icon: {
                            option.menuIcon
                        }
                        .tag(Optional(option))
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                Label("Filter", systemImage: status.wrappedValue == nil ?
                      "line.3.horizontal.decrease" :
                        "line.3.horizontal.decrease.circle.fill"
                )
            }
            .help("Filter Postcards")
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


