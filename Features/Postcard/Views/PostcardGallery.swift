import SwiftUI
import Flow

struct PostcardGallery: View {
    let postcards: [PostcardSummary]
    let isSelected: (PostcardSummary) -> Bool
    let onSelect: (PostcardSummary) -> Void
    let onDelete: (PostcardSummary) -> Void
    let clearSelection: () -> Void
    
    private let postcardRepo = PostcardRepository.shared
    
    @State private var cardWidth: CGFloat = 175
    private let gap: CGFloat = 20
    
    private var visibleSelectedCount: Int {
        postcards.filter { isSelected($0) }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: cardWidth), spacing: gap)],
                    spacing: gap
                ) {
                    ForEach(postcards, id: \.id) { postcard in
                        PostcardCard(
                            postcard: postcard,
                            cardWidth: cardWidth,
                            isSelected: isSelected(postcard)
                        )
                        .contextMenu {
                            let count = isSelected(postcard) ? visibleSelectedCount : 1
                            
                            Button(role: .destructive) {
                                onDelete(postcard)
                            } label: {
                                Label(
                                    count == 1 ? "Delete 1 Postcard" : "Delete \(count) Postcards",
                                    systemImage: "trash"
                                )
                            }
                        }
                        .onTapGesture { onSelect(postcard) }
                        .onAppear {
                            Task {
                                if postcard.id == postcards.last?.id {
                                    try await postcardRepo.loadNextPage()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .onTapGesture { clearSelection() }
            HStack {
                Spacer()
                    .frame(width: 100)

                Spacer()

                Text(
                    visibleSelectedCount > 0
                    ? "\(visibleSelectedCount) of \(postcards.count) selected"
                    : "\(postcards.count) postcards"
                )
                .foregroundStyle(.secondary)
                .font(.subheadline)
                
                Spacer()
                
                Slider(value: $cardWidth, in: 125...225)
                    .frame(width: 100)
            }
            .padding(.horizontal, gap)
            .padding(.vertical, 8)
        }
    }
}
