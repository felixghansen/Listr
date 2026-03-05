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
    private let padding: CGFloat = 16

    @StateObject private var editor: PostcardEditor
    @State private var showDeleteConfirmation = false
    @State private var deleteErrorMessage: String? = nil
    private var showDeleteErrorMessage: Binding<Bool> {
        Binding<Bool>(
            get: { deleteErrorMessage != nil },
            set: { newValue in if !newValue { deleteErrorMessage = nil } }
        )
    }

    init(
        postcard: PostcardDetails,
        onSave: @escaping (PostcardDetails) -> Void
    ) {
        self.postcard = postcard
        self.onSave = onSave
        _editor = StateObject(wrappedValue: PostcardEditor(postcard: postcard))
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    ImageCarousel(
                        imageURLs: [
                            postcard.frontImageURL,
                            postcard.backImageURL
                        ],
                        containerWidth: geo.size.width - 2 * padding
                    )
                    //                .transaction { $0.animation = nil }
                    
                    
                    StatusSection(status: postcard.status)
                    
                    Divider()
                    
                    BasicInfoSection(
                        title: $editor.draft.aiData.title,
                        description: $editor.draft.aiData.description,
                        era: $editor.draft.aiData.era
                    )
                    
                    Divider()
                    
                    TypeSection(
                        material: $editor.draft.aiData.type.material,
                        style: $editor.draft.aiData.type.style
                    )
                    
                    Divider()
                    
                    PostalInfoSection(
                        postmarkDate: $editor.draft.aiData.postmarkDate,
                        mailingOrigin: $editor.draft.aiData.mailingOrigin
                    )
                    
                    Divider()
                    
                    PublisherSection(
                        publisher: $editor.draft.aiData.publisher,
                        condition: $editor.draft.aiData.condition
                    )
                    
                    Divider()
                    
                    KeywordsSection(
                        keywords: $editor.draft.aiData.keywords
                    )
                    
                    Divider()
                    
                    PricingSection(
                        price: $editor.draft.aiData.suggestedPriceCAD.price,
                        auctionStart: $editor.draft.aiData.suggestedPriceCAD.auctionStart
                    )
                    
                    Divider()
                    
                    MetadataSection(
                        scannedAt: postcard.scannedAt,
                        batchID: postcard.batchID,
                        ebayCategoryID: $editor.draft.aiData.ebayCategoryID
                    )
                    
                    HStack {
                        Button {
                            guard let updated = editor.commitAndReset() else {
                                return
                            }
                            
                            Task {
                                try await PostcardRepository.shared.updatePostcard(updated)
                                onSave(updated)
                            }
                        } label: {
                            Text("Save")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!editor.hasChanges)
                        
                        //                    .confirmationDialog(
                        //                        "Delete postcard?",
                        //                        isPresented: $showDeleteConfirmation,
                        //                        titleVisibility: .visible
                        //                    ) {
                        //                        Button("Delete", role: .destructive) {
                        //                            Task {
                        //                                do {
                        //                                    try await PostcardRepository.shared.deletePostcard(postcard)
                        //                                    onDelete()
                        //                                } catch {
                        //                                    assertionFailure("Failed to delete postcard: \(error)")
                        //                                    deleteErrorMessage = "Failed to delete postcard. Please try again."
                        //                                }
                        //                            }
                        //                        }
                        //                        Button("Cancel", role: .cancel) {}
                        //                    } message: { // todo: recently deleted
                        //                        Text("""
                        //                        This postcard will be deleted from your collection.
                        //                        It will remain in Recently Deleted for 30 days.
                        //                        """)
                        //                    }
                    }
                }
                .padding(padding)
            }
            .onChange(of: postcard.id) { _, _ in
                editor.reset(with: postcard)
            }
            .alert("Error", isPresented: showDeleteErrorMessage) {
                Button("OK", role: .cancel) { deleteErrorMessage = nil }
            } message: {
                Text(deleteErrorMessage ?? "")
            }
        }
    }
}



// MARK: - Status Section
struct StatusSection: View {
    let status: PostcardStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
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
        }
    }
}

// MARK: - Basic Info Section
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
                Text("Era")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $era)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: - Type Section
struct TypeSection: View {
    @Binding var material: String
    @Binding var style: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Material")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $material)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Style")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $style)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: - Postal Info Section
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

// MARK: - Publisher Section
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

// MARK: - Keywords Section
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

// MARK: - Drag and Drop Delegate
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

// MARK: - Pricing Section
struct PricingSection: View {
    @Binding var price: Double
    @Binding var auctionStart: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pricing (CAD)")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buy It Now")
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
                    Text("Auction Start")
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
    }
}

// MARK: - Metadata Section
struct MetadataSection: View {
    let scannedAt: Date
    let batchID: String
    @Binding var ebayCategoryID: Int
    @State var ebayCategoryIDText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Scanned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(scannedAt, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Batch ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(batchID)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("eBay Category ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $ebayCategoryIDText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.tertiary)
                    .cornerRadius(6)
                    .onChange(of: ebayCategoryIDText){ _, newValue in
                        let digits = newValue.filter { $0.isNumber }
                        if digits != newValue { ebayCategoryIDText = digits }
                        ebayCategoryID = Int(digits) ?? 0
                    }
                    .onAppear {
                        ebayCategoryIDText = String(ebayCategoryID)
                    }
            }
        }
    }
}

