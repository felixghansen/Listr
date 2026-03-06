//
//  Popup.swift
//  Listr
//
//  Created by Felix on 12/31/25.
//

import SwiftUI

enum PopupStyle: Equatable {
    case info
    case success
    case warning
    case error
    case progress(Double?)

    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .progress: return "arrow.triangle.2.circlepath.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info: return .accentColor
        case .success: return .green
        case .warning: return .yellow
        case .error: return .red
        case .progress: return .accentColor
        }
    }
}

struct Popup: View {
    var style: PopupStyle
    var title: String
    var message: String?

    var primaryActionTitle: String?
    var primaryAction: (() -> Void)?

    var secondaryActionTitle: String?
    var secondaryAction: (() -> Void)?

    init(
        style: PopupStyle,
        title: String,
        message: String? = nil,
        primaryActionTitle: String? = nil,
        primaryAction: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.style = style
        self.title = title
        self.message = message
        self.primaryActionTitle = primaryActionTitle
        self.primaryAction = primaryAction
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: style.iconName)
                    .foregroundStyle(style.tint, .secondary)
                    .font(.system(size: 28, weight: .semibold))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let message, !message.isEmpty {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }

            if case let .progress(value) = style {
                if let value {
                    ProgressView(value: value)
                        .progressViewStyle(.linear)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                }
            }

            if primaryActionTitle != nil || secondaryActionTitle != nil {
                HStack(spacing: 8) {
                    Spacer()
                    if let secondaryActionTitle {
                        Button(secondaryActionTitle) { secondaryAction?() }
                    }
                    if let primaryActionTitle {
                        Button(primaryActionTitle) { primaryAction?() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .frame(maxWidth: 500)
    }
}
