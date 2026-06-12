//
//  SequenceLogo.swift
//  Sequence
//
//  The app mark, drawn in SwiftUI as a small contribution grid so no raster
//  asset is required. Used on the splash and onboarding.
//

import SwiftUI

struct SequenceLogo: View {
    var size: CGFloat = 96
    /// 0…1 reveal progress for the populate animation (1 = fully shown).
    var progress: Double = 1

    private let dimension = 4
    private let hex = "48A69E"

    var body: some View {
        let spacing = size * 0.08
        let cell = (size - spacing * CGFloat(dimension - 1)) / CGFloat(dimension)
        VStack(spacing: spacing) {
            ForEach(0..<dimension, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<dimension, id: \.self) { col in
                        let index = row * dimension + col
                        let level = levelFor(row: row, col: col)
                        RoundedRectangle(cornerRadius: cell * 0.24, style: .continuous)
                            .fill(ColorScaleEngine.color(forHex: hex, level: level))
                            .frame(width: cell, height: cell)
                            .opacity(Double(index) / 16.0 <= progress ? 1 : 0)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }

    /// A pleasing diagonal intensity gradient across the mark.
    private func levelFor(row: Int, col: Int) -> IntensityLevel {
        let raw = 1 + (row + col) % 5
        return IntensityLevel(rawValue: raw) ?? .full
    }
}

#Preview {
    SequenceLogo(size: 120).padding().background(SequenceColor.background)
}
