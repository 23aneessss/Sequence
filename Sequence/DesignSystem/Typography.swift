//
//  Typography.swift
//  Sequence
//
//  Authoritative type scale. Reference: product_design.md §3.1 / §3.2.
//  Uses the San Francisco system font for native ProMotion-grade clarity.
//
//  RULE: Use these style modifiers — do not hand-tune font/weight/tracking inline.
//

import SwiftUI

/// The four roles in the Sequence type scale.
enum SequenceTextStyle {
    /// App title / branding — SemiBold 22pt, tight tracking, ALL CAPS, textPrimary.
    case appTitle
    /// Section headers — Bold 16pt, -0.24 tracking, textPrimary.
    case sectionHeader
    /// Habit title / core metric — Medium 15pt, textPrimary.
    case habitTitle
    /// Subtext / metadata — Regular 12pt, textSecondary.
    case subtext

    var font: Font {
        switch self {
        case .appTitle:      return .system(size: 22, weight: .semibold)
        case .sectionHeader: return .system(size: 16, weight: .bold)
        case .habitTitle:    return .system(size: 15, weight: .medium)
        case .subtext:       return .system(size: 12, weight: .regular)
        }
    }

    var tracking: CGFloat {
        switch self {
        case .appTitle:      return -0.2   // "tight"
        case .sectionHeader: return -0.24
        case .habitTitle:    return 0
        case .subtext:       return 0
        }
    }

    var color: Color {
        switch self {
        case .appTitle, .sectionHeader, .habitTitle: return SequenceColor.textPrimary
        case .subtext:                               return SequenceColor.textSecondary
        }
    }

    /// App title is rendered all-caps per §3.2.
    var isUppercased: Bool { self == .appTitle }
}

private struct SequenceTextStyleModifier: ViewModifier {
    let style: SequenceTextStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .foregroundStyle(style.color)
    }
}

extension View {
    /// Applies a Sequence type-scale role (font, weight, tracking, color).
    func sequenceTextStyle(_ style: SequenceTextStyle) -> some View {
        modifier(SequenceTextStyleModifier(style: style))
    }
}

extension Text {
    /// Convenience for `Text` that also handles all-caps transformation for the app title.
    func sequenceStyle(_ style: SequenceTextStyle) -> some View {
        Group {
            if style.isUppercased {
                self.textCase(.uppercase).sequenceTextStyle(style)
            } else {
                self.sequenceTextStyle(style)
            }
        }
    }
}
