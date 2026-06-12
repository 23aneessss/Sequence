//
//  DefaultPalette.swift
//  Sequence
//
//  The six pre-loaded habit colours. Reference: app_concept.md §9.3.
//  Phase 8 makes the palette user-managed; until then these are the choices
//  offered in habit creation.
//

import Foundation

enum DefaultPalette {

    struct Swatch: Identifiable, Equatable {
        let name: String
        let hex: String
        var id: String { hex }
    }

    static let swatches: [Swatch] = [
        Swatch(name: "Sequence Teal", hex: "48A69E"),
        Swatch(name: "Electric Blue", hex: "4A90E2"),
        Swatch(name: "Warm Amber",   hex: "E6A817"),
        Swatch(name: "Coral Red",    hex: "E05C5C"),
        Swatch(name: "Soft Purple",  hex: "8E6FD8"),
        Swatch(name: "Forest Green", hex: "3D8B37")
    ]

    static let defaultHex = swatches[0].hex
}
