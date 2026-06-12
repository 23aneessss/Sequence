//
//  DesignSystemPreview.swift
//  Sequence
//
//  Phase 1 acceptance-gate harness. Renders the full design system so the
//  foundation can be verified on a real simulator in light AND dark:
//    • all color tokens          (product_design.md §2)
//    • the type scale            (§3)
//    • the three spring curves   (§5.1)
//    • the core components       (§5.2, §6.2, §8.2)
//
//  This screen is scaffolding — it is replaced by the real app surfaces in
//  later phases (see AppRouter / RootView).
//

import SwiftUI

struct DesignSystemPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                header
                TypeScaleSection()
                ColorTokenSection()
                AnimationSection()
                ComponentSection()
            }
            .padding(SequenceSpacing.screenMargin)
        }
        .background(SequenceColor.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.half) {
            Text("Sequence").sequenceStyle(.appTitle)
            Text("Design System · Phase 1").sequenceTextStyle(.subtext)
        }
    }
}

// MARK: - Type Scale

private struct TypeScaleSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Typography").sequenceTextStyle(.sectionHeader)
            Text("Section Header").sequenceTextStyle(.sectionHeader)
            Text("Habit Title / Core Metric").sequenceTextStyle(.habitTitle)
            Text("Subtext / metadata").sequenceTextStyle(.subtext)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Color Tokens

private struct ColorTokenSection: View {
    private let swatches: [(String, Color)] = [
        ("background", SequenceColor.background),
        ("surfacePrimary", SequenceColor.surfacePrimary),
        ("surfaceSecondary", SequenceColor.surfaceSecondary),
        ("borderOpaque", SequenceColor.borderOpaque),
        ("navySlate", SequenceColor.navySlate),
        ("mintTeal", SequenceColor.mintTeal),
        ("accentTeal", SequenceColor.accentTeal)
    ]

    private let columns = [GridItem(.adaptive(minimum: 88), spacing: SequenceSpacing.item)]

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Color Tokens").sequenceTextStyle(.sectionHeader)
            LazyVGrid(columns: columns, spacing: SequenceSpacing.item) {
                ForEach(swatches, id: \.0) { name, color in
                    swatch(name: name, color: color)
                }
            }
        }
    }

    private func swatch(name: String, color: Color) -> some View {
        VStack(spacing: SequenceSpacing.half) {
            RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                .fill(color)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .strokeBorder(SequenceColor.borderOpaque, lineWidth: 1)
                )
            Text(name).sequenceTextStyle(.subtext).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

// MARK: - Animations

private struct AnimationSection: View {
    @State private var structural = false
    @State private var fluid = false

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Spring Curves").sequenceTextStyle(.sectionHeader)
            HStack(spacing: SequenceSpacing.item) {
                springChip(label: "Structural", on: structural) {
                    withAnimation(.sequenceStructural) { structural.toggle() }
                }
                .scaleEffect(structural ? 1.15 : 1.0)

                springChip(label: "Fluid", on: fluid) {
                    withAnimation(.sequenceFluid) { fluid.toggle() }
                }
                .rotationEffect(.degrees(fluid ? 12 : 0))
            }
            Text("Micro spring is demonstrated by the checkmark & buttons below.")
                .sequenceTextStyle(.subtext)
        }
    }

    private func springChip(label: String, on: Bool, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            Text(label)
                .sequenceTextStyle(.habitTitle)
                .padding(.horizontal, SequenceSpacing.cardPadding)
                .padding(.vertical, SequenceSpacing.item)
                .background(
                    RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(on ? SequenceColor.mintTeal.opacity(0.25) : SequenceColor.surfaceSecondary)
                )
        }
        .buttonStyle(SequencePressStyle())
    }
}

// MARK: - Components

private struct ComponentSection: View {
    @State private var checked = false

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Components").sequenceTextStyle(.sectionHeader)

            HStack(spacing: SequenceSpacing.item) {
                SequenceCheckmarkButton(isCompleted: checked) { checked.toggle() }
                Text(checked ? "Completed" : "Tap to complete").sequenceTextStyle(.habitTitle)
            }

            DashedEmptyState(
                title: "No habits yet",
                message: "Tap + to start your first Sequence."
            )

            VStack(alignment: .leading, spacing: SequenceSpacing.item) {
                ShimmerView().frame(height: 16)
                ShimmerView().frame(width: 160, height: 16)
            }

            PrimaryButton(title: "Start Sequence") {}
        }
    }
}

#Preview {
    DesignSystemPreview()
}
