import SwiftUI
import Flow

struct PostcardGallery: View {
    let postcards: [PostcardSummary]
    let isSelected: (PostcardSummary) -> Bool
    let onSelect: (PostcardSummary) -> Void
    let clearSelection: () -> Void
    
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
                        .onTapGesture { onSelect(postcard) }
                    }
                }
            }
            .padding()
            .onTapGesture { clearSelection() }
            HStack {
                Spacer()
                    .frame(width: 100)
                    .background(Color.red.opacity(0.1))
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
