import Foundation

func topGradientMultiplier(
    scrollOffset: CGFloat,
    threshold: CGFloat = 100
) -> CGFloat {

    guard threshold > 0 else { return 0 }

    // progress: 0 → 1 as you scroll down `threshold` points
    let progress = scrollOffset / threshold

    // multiplier: 1 → 0
    return max(0, min(1, 1 - progress))
}

func bottomGradientMultiplier(
    scrollOffset: CGFloat,
    contentHeight: CGFloat,
    scrollHeight: CGFloat,
    threshold: CGFloat = 100
) -> CGFloat {

    guard threshold > 0 else { return 0 }

    let maxOffset = contentHeight - scrollHeight
    guard maxOffset > 0 else { return 0 }

    // distance from bottom: 0 at bottom, threshold+ at far away
    let distance = maxOffset - scrollOffset

    let progress = distance / threshold

    return max(0, min(1, 1 - progress))
}
