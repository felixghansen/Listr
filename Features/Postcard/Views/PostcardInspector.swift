import SwiftUI

struct PostcardInspector: View {
    let selectedPostcards: [PostcardDetails]
    var onSave: (PostcardDetails) async throws -> Void
    var onListEbay: () async throws -> Void
    var onUpdateEbay: () async throws -> Void
    
    var body: some View {
        Group {
            if selectedPostcards.count == 1, let selected = selectedPostcards.first {
                EditorContent(
                    postcard: selected,
                    onSave: onSave,
                    onListEbay: onListEbay,
                    onUpdateEbay: onUpdateEbay
                )
                .id(selected.id)
            } else {
                InspectorPlaceholder()
            }    
        }
    }
}

private struct InspectorPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Selection")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Select a postcard to view details")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
