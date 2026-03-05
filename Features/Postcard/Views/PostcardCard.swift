import SwiftUI
import AppKit

struct PostcardCard: View {
    let postcard: PostcardSummary
    let cardWidth: CGFloat
    let isSelected: Bool

    private let cornerRadius: CGFloat = 12
    private let cardAspectRatio: CGFloat = 4/3

    var body: some View {
        VStack(spacing: 8) {
            PostcardImage(
                url: postcard.frontImageURL,
                scaledTo: .fill
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(postcard.status.color)
                    .frame(width: 8, height: 8)
                    .padding(8)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.accentColor, lineWidth: 3)
                }
            }

            Text(postcard.title)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .allowsTightening(true)
                .lineSpacing(1)
                .padding(.horizontal, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: cardWidth)
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
