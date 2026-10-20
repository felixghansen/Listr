//
//  EditorContent.swift
//  Listr
//
//  Created by Felix on 12/23/25.
//

import SwiftUI
import Flow

struct EditorContent: View {
    let postcard: PostcardDetails
    let onSave: (PostcardDetails) -> Void
    let onListEbay: () async throws -> Void
    let onUpdateEbay: () async throws -> Void

    @Environment(\.openURL) private var openURL
    
    private let padding: CGFloat = 16

    @StateObject private var editor: PostcardEditor
    
    @State private var isListing = false
    @State private var isUpdating = false
    
    @State private var errorTitle = ""
    @State private var errorMessage: String?

    private func showError(_ title: String, _ error: Error) {
        errorTitle = title
        errorMessage = error.localizedDescription
    }
    
    private var showErrorMessage: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isShowing in
                if !isShowing {
                    errorMessage = nil
                }
            }
        )
    }
    
    @ViewBuilder
    private var viewOnEbayButton: some View {
        if let listingId = postcard.ebayListingId,
           let url = URL(string: "https://sandbox.ebay.com/itm/\(listingId)") {
            Button("View on eBay") {
                openURL(url)
            }
        }
    }

    init(
        postcard: PostcardDetails,
        onSave: @escaping (PostcardDetails) -> Void,
        onListEbay: @escaping () async throws -> Void,
        onUpdateEbay: @escaping () async throws -> Void
    ) {
        self.postcard = postcard
        self.onSave = onSave
        self.onListEbay = onListEbay
        self.onUpdateEbay = onUpdateEbay
        _editor = StateObject(wrappedValue: PostcardEditor(postcard: postcard))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ImageCarousel(
                    imageURLs: [
                        postcard.frontImageURL,
                        postcard.backImageURL
                    ]
                )
                
                OverviewSection(
                    status: postcard.status,
                    scannedAt: postcard.scannedAt
                )
                
                Divider()
                
                BasicInfoSection(
                    title: $editor.draft.title,
                    description: $editor.draft.description,
                    era: $editor.draft.era
                )
                
                Divider()
                
                TypeSection(
                    material: $editor.draft.type.material,
                    style: $editor.draft.type.style
                )
                
                Divider()
                
                PostalInfoSection(
                    postmarkDate: $editor.draft.postmarkDate,
                    mailingOrigin: $editor.draft.mailingOrigin
                )
                
                Divider()
                
                PublisherSection(
                    publisher: $editor.draft.publisher,
                    condition: $editor.draft.condition
                )
                
                Divider()
                
                KeywordsSection(
                    keywords: $editor.draft.keywords
                )
                
                Divider()
                
                ListingSection(
                     ebayCategoryID: $editor.draft.ebayCategoryID,
                     price: $editor.draft.suggestedPrice.price,
                     auctionStart: $editor.draft.suggestedPrice.auctionStart
                 )

                HStack {
                    if postcard.status != .sold {
                        Button("Save") {
                            let updated = editor.commitAndReset()
                            
                            Task {
                                try await PostcardRepository.shared.updatePostcard(updated)
                                onSave(updated)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!editor.hasChanges)
                    }
                    
                    switch postcard.status {
                    case .needsReview:
                        EmptyView()
                        
                    case .readyToList:
                        Button {
                            Task {
                                isListing = true
                                
                                do {
                                    try await onListEbay()
                                    isListing = false
                                } catch {
                                    showError("Couldn't list on eBay", error)
                                }
                            }
                        } label: {
                            if isListing {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Listing...")
                                }
                            } else {
                                Text("List on eBay")
                            }
                        }
                        .disabled(editor.hasChanges || isListing)

                    case .listed:
                        Button {
                            Task {
                                isUpdating = true
                                
                                do {
                                    try await onUpdateEbay()
                                    isUpdating = false
                                } catch {
                                    showError("Couldn't update on eBay", error)
                                }
                            }
                        } label: {
                            if isUpdating {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Updating...")
                                }
                            } else {
                                Text("Update on eBay")
                            }
                        }
                        .disabled(editor.hasChanges || isUpdating)

                        viewOnEbayButton

                    case .sold:
                        viewOnEbayButton
                    }
                }
            }
            .padding(padding)
        }
        .onChange(of: postcard.id) { _, _ in
            editor.reset(with: postcard)
        }
        .alert(errorTitle, isPresented: showErrorMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

struct OverviewSection: View {
    let status: PostcardStatus
    let scannedAt: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                Text(status.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("Scanned \(scannedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct BasicInfoSection: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var era: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Information")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DynamicTextEditor(text: $description)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Era")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if era == "Unknown" {
                        Text("(required)")
                            .foregroundStyle(era == "Unknown" ? .red : .secondary)
                    }
                }
                .font(.caption)

                Picker("Era", selection: $era) {
                    Text("Select an era...").tag("Unknown")
                    ForEach(EbayAspectValues.era.filter { $0 != "Unknown" }, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

            }
        }
    }
}

struct TypeSection: View {
    @Binding var material: String
    @Binding var style: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Material")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if material == "Unknown" {
                        Text("(required)")
                            .foregroundStyle(material == "Unknown" ? .red : .secondary)
                    }
                }
                .font(.caption)

                
                Picker("Material", selection: $material) {
                    Text("Select a material...")
                        .tag("Unknown")
                    ForEach(EbayAspectValues.material.filter { $0 != "Unknown" }, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Style")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if style == "Unknown" {
                        Text("(required)")
                            .foregroundStyle(style == "Unknown" ? .red : .secondary)
                    }
                }
                .font(.caption)
                Picker("Style", selection: $style) {
                    Text("Select a style...").tag("Unknown")
                    ForEach(EbayAspectValues.style.filter { $0 != "Unknown" }, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct PostalInfoSection: View {
    @Binding var postmarkDate: String
    @Binding var mailingOrigin: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Postal Information")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Postmark Date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $postmarkDate)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mailing Origin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $mailingOrigin)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
            }
        }
    }
}

struct PublisherSection: View {
    @Binding var publisher: String
    @Binding var condition: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Publisher")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $publisher)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Condition")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $condition)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
            }
        }
    }
}

struct KeywordsSection: View {
    @Binding var keywords: [String]
    @State private var newKeyword: String = ""
    @State private var draggedKeyword: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keywords")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Add keyword text field
            HStack(spacing: 8) {
                TextField("Add keyword...", text: $newKeyword)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
                    .onSubmit {
                        addKeyword()
                    }
                
                Button(action: addKeyword) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .disabled(newKeyword.trimmingCharacters(in: .whitespaces).isEmpty)
                .frame(width: 32, height: 32)
                .background(.tertiary)
                .cornerRadius(6)
            }
            
            // Keywords chips with drag to reorder
            HFlow(spacing: 6) {
                ForEach(keywords, id: \.self) { keyword in
                    Chip(
                        text: keyword,
                        style: .tertiary,
                        isSelected: true,
                        onRemove: {
                            removeKeyword(keyword)
                        }
                    )
                    .opacity(draggedKeyword == keyword ? 0.5 : 1.0)
                    .onDrag {
                        self.draggedKeyword = keyword
                        return NSItemProvider(object: keyword as NSString)
                    }
                    .onDrop(of: [.text], delegate: KeywordDropDelegate(
                        keyword: keyword,
                        keywords: $keywords,
                        draggedKeyword: $draggedKeyword
                    ))
                }
            }
            
            if !keywords.isEmpty {
                Text("Drag to reorder • First keywords rank higher")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func addKeyword() {
        let trimmed = newKeyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !keywords.contains(trimmed) else { return }
        keywords.append(trimmed)
        newKeyword = ""
    }
    
    private func removeKeyword(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
    }
}

struct KeywordDropDelegate: DropDelegate {
    let keyword: String
    @Binding var keywords: [String]
    @Binding var draggedKeyword: String?
    
    func performDrop(info: DropInfo) -> Bool {
        draggedKeyword = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedKeyword = draggedKeyword,
              draggedKeyword != keyword,
              let fromIndex = keywords.firstIndex(of: draggedKeyword),
              let toIndex = keywords.firstIndex(of: keyword) else {
            return
        }
        
        withAnimation(.default) {
            keywords.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
}

enum EbayPostcardCategory {
    static let topographical = 262042
    static let nonTopographical = 262043
}

struct ListingSection: View {
    @Binding var ebayCategoryID: Int
    @Binding var price: Double
    @Binding var auctionStart: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("eBay Listing")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Category", selection: $ebayCategoryID) {
                    Text("Topographical").tag(EbayPostcardCategory.topographical)
                    Text("Non-Topographical").tag(EbayPostcardCategory.nonTopographical)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price (USD)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("", value: $price, format: .number.precision(.fractionLength(2)))
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Auction Start (USD)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("", value: $auctionStart, format: .number.precision(.fractionLength(2)))
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
                }
            }
        }
        .onAppear {
            // Older postcards may have an AI-guessed ID that isn't one of the two valid categories.
            if ebayCategoryID != EbayPostcardCategory.topographical && ebayCategoryID != EbayPostcardCategory.nonTopographical {
                ebayCategoryID = EbayPostcardCategory.topographical
            }
        }
    }
}

//#Preview {
//    BasicInfoSection(
//        title: .constant("Nuremberg Germany St Lorenz Church Tram DB c1910s"),
//        description: .constant("Vintage postcard of St. Lorenz Church in Nuremberg."),
//        era: .constant("Unknown")
//    )
//    .padding()
//    .frame(width: 400)
//}
