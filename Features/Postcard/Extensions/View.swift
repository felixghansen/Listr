import Foundation
import SwiftUI

extension View {
    func scrollGradient(
        gradientHeight: CGFloat = 50,
        scrollOffset: CGFloat,
        scrollHeight: CGFloat,
        contentHeight: CGFloat,
        fadeDistance: CGFloat = 80,
        maxOpacity: CGFloat = 0.3
    ) -> some View {
        let maxOffset = max(contentHeight - scrollHeight, 0) // the max offset achieved, starting from the top of the ScrollView, to the top of the visible container

        let topOpacity: CGFloat
        let bottomOpacity: CGFloat

        if maxOffset <= 0 { // when scrolling not possible
            topOpacity = 0
            bottomOpacity = 0
        } else {
            let clampedOffset = min(max(scrollOffset, 0), maxOffset)
            let distanceFromBottom = max(maxOffset - clampedOffset, 0)

            let topProgress = min(clampedOffset / fadeDistance, 1)
            topOpacity = maxOpacity * topProgress

            let bottomProgress = min(distanceFromBottom / fadeDistance, 1)
            bottomOpacity = maxOpacity * bottomProgress
        }

        return self
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(topOpacity), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: gradientHeight)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color.black.opacity(bottomOpacity)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: gradientHeight)
                .allowsHitTesting(false)
            }
    }
}
