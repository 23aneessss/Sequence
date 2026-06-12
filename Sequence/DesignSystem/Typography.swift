//
//  Typography.swift
//  Sequence
//
//  Authoritative type scale. Reference: product_design.md §3.1 / §3.2.
//  Uses SF Pro Rounded for a friendly, modern, high-clarity feel — warmer than
//  the default grotesque while staying native and ProMotion-crisp.
//
//  RULE: Use these style modifiers — do not hand-tune font/weight/tracking inline.
//

import SwiftUI

/// The roles in the Sequence type scale.
enum SequenceTextStyle {
    /// Personalized screen greeting — Bold 26pt, rounded, mixed case.
    case greeting
    /// App title / branding — Bold 22pt, tight tracking, ALL CAPS.
    case appTitle
    /// Section headers — Bold 17pt.
    case sectionHeader
    /// Habit title / core metric — Medium 16pt.
    case habitTitle
    /// Subtext / metadata — Regular 13pt, textSecondary.
    case subtext

    var font: Font {
        switch self {
        case .greeting:      return .system(size: 26, weight: .bold,     design: .rounded)
        case .appTitle:      return .system(size: 22, weight: .bold,     design: .rounded)
        case .sectionHeader: return .system(size: 17, weight: .bold,     design: .rounded)
        case .habitTitle:    return .system(size: 16, weight: .medium,   design: .rounded)
        case .subtext:       return .system(size: 13, weight: .regular,  design: .rounded)
        }
    }

    var tracking: CGFloat {
        switch self {
        case .greeting:      return -0.4
        case .appTitle:      return 0.4    // caps breathe a little
        case .sectionHeader: return -0.24
        case .habitTitle:    return -0.1
        case .subtext:       return 0
        }
    }

    var color: Color {
        switch self {
        case .subtext: return SequenceColor.textSecondary
        default:       return SequenceColor.textPrimary
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
