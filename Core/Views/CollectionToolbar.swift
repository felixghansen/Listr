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
        ToolbarItemGroup(placement: .automatic) {
            Button(action: onImport) {
                Image(systemName: "square.and.arrow.down")
            }
        }
    }

    
    @ToolbarContentBuilder
    static func filterAndSortButtons(
        filter: Binding<PostcardFilter>
    ) -> some ToolbarContent {

        ToolbarItemGroup(placement: .primaryAction) {

            Menu {
                FilterMenu(filter: filter)
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }

            Menu {
                SortMenu(filter: filter)
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
    }

    @ToolbarContentBuilder
    static func inspectorButton(
        showInspector: Binding<Bool>
    ) -> some ToolbarContent {

        ToolbarItem(placement: .automatic) {
            Button {
                showInspector.wrappedValue.toggle()
            } label: {
                Image(systemName: "sidebar.right")
            }
            .help(showInspector.wrappedValue ? "Hide Inspector" : "Show Inspector")
        }
    }

    private struct MenuRow: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .frame(width: 16, alignment: .leading)
                    } else {
                        Spacer()
                            .frame(width: 16)
                    }
                    
                    Text(title)
                    Spacer()
                }
            }
        }
    }


    private struct FilterMenu: View {
        @Binding var filter: PostcardFilter

        var body: some View {
            ForEach(PostcardStatus.allCases, id: \.self) { status in
                MenuRow(
                    title: status.rawValue.capitalized,
                    isSelected: filter.status == status
                ) {
                    filter.status = (filter.status == status) ? nil : status
                }
            }
        }
    }

    private struct SortMenu: View {
        @Binding var filter: PostcardFilter

        private var currentSort: PostcardSortOrder { filter.sortOrder }

        var body: some View {
            // Sort type
            MenuRow(
                title: "Date Scanned",
                isSelected: isDate,
            ) {
                filter.sortOrder = .scannedAt(descending: currentSort.isDescending)
            }
            
            MenuRow(
                title: "Price",
                isSelected: isPrice
            ) {
                filter.sortOrder = .price(descending: currentSort.isDescending)
            }

            Divider()

            // Sort direction
            MenuRow(
                title: "Ascending",
                isSelected: !currentSort.isDescending
            ) {
                setDescending(false)
            }
            MenuRow(
                title: "Descending",
                isSelected: currentSort.isDescending
            ) {
                setDescending(true)
            }
        }

        private var isDate: Bool {
            if case .scannedAt = currentSort { return true }
            return false
        }

        private var isPrice: Bool {
            if case .price = currentSort { return true }
            return false
        }

        private func setDescending(_ descending: Bool) {
            switch currentSort {
            case .scannedAt:
                filter.sortOrder = .scannedAt(descending: descending)
            case .price:
                filter.sortOrder = .price(descending: descending)
            }
        }
    }
}


