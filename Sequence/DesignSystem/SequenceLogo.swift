//
//  SequenceLogo.swift
//  Sequence
//
//  The app mark, drawn in SwiftUI as a small contribution grid so no raster
//  asset is required. Used on the splash, auth, and onboarding.
//
//  With `animated: true` the 16 cells "build" — each square pops in one-by-one
//  in reading order, so the mark assembles itself rather than just appearing.
//

import SwiftUI

struct SequenceLogo: View {
    var size: CGFloat = 96
    /// When true, the cells pop in one-by-one on appear (the build animation).
    var animated: Bool = false

    @State private var built = false

    private let dimension = 4
    private let hex = DefaultPalette.defaultHex
    /// Seconds between each cell appearing during the build.
    private let perCellDelay = 0.05

    var body: some View {
        let spacing = size * 0.08
        let cell = (size - spacing * CGFloat(dimension - 1)) / CGFloat(dimension)
        VStack(spacing: spacing) {
            ForEach(0..<dimension, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<dimension, id: \.self) { col in
                        cellView(row: row, col: col, side: cell)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { if animated { built = true } }
    }

    private func cellView(row: Int, col: Int, side: CGFloat) -> some View {
        let order = row * dimension + col          // reading order → one-by-one
        let shown = !animated || built
        return RoundedRectangle(cornerRadius: side * 0.24, style: .continuous)
            .fill(ColorScaleEngine.color(forHex: hex, level: levelFor(row: row, col: col)))
            .frame(width: side, height: side)
            .scaleEffect(shown ? 1 : 0.2)
            .opacity(shown ? 1 : 0)
            .animation(.sequenceStructural.delay(Double(order) * perCellDelay), value: built)
    }

    /// A pleasing diagonal intensity gradient across the mark.
    private func levelFor(row: Int, col: Int) -> IntensityLevel {
        let raw = 1 + (row + col) % 5
        return IntensityLevel(rawValue: raw) ?? .full
    }
}

#Preview {
    SequenceLogo(size: 120, animated: true).padding().background(SequenceColor.background)
}
