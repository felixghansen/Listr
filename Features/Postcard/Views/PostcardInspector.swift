import SwiftUI

struct PostcardInspector: View {
    @Binding var selectedPostcards: [PostcardDetails]
    
    var body: some View {
        Group {
            if selectedPostcards.count == 1, let selected = selectedPostcards.first {
                EditorContent(
                    postcard: selected,
                    onSave: { updated in
                        if let idx = selectedPostcards.firstIndex(where: { $0.id == updated.id }) {
                            selectedPostcards[idx] = updated
                        }
                    }
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
