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
        Swatch(name: "Mint",          hex: "2BB673"),
        Swatch(name: "Forest Green",  hex: "3D8B37"),
        Swatch(name: "Lime",          hex: "7CB342"),
        Swatch(name: "Electric Blue", hex: "4A90E2"),
        Swatch(name: "Sky",           hex: "33B5E5"),
        Swatch(name: "Indigo",        hex: "5C6BC0"),
        Swatch(name: "Soft Purple",   hex: "8E6FD8"),
        Swatch(name: "Violet",        hex: "B65FCF"),
        Swatch(name: "Magenta",       hex: "D9489E"),
        Swatch(name: "Rose",          hex: "EC5F8A"),
        Swatch(name: "Coral Red",     hex: "E05C5C"),
        Swatch(name: "Sunset",        hex: "F0663F"),
        Swatch(name: "Warm Amber",    hex: "E6A817"),
        Swatch(name: "Gold",          hex: "F2B807"),
        Swatch(name: "Clay",          hex: "C17F59"),
        Swatch(name: "Slate",         hex: "5E7488"),
        Swatch(name: "Graphite",      hex: "6E6E78")
    ]

    static let defaultHex = swatches[0].hex
}
