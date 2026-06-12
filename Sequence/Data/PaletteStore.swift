//
//  PaletteStore.swift
//  Sequence
//
//  The user's personal colour palette. Reference: app_concept.md §9.3.
//  Seeded with six defaults; supports adding custom colours and removing
//  unused ones (the caller enforces the in-use guard).
//

import Foundation
import Observation

@Observable
final class PaletteStore {

    struct Swatch: Identifiable, Equatable, Codable {
        let name: String
        let hex: String
        var id: String { hex }
    }

    private let defaults = UserDefaults.standard
    private let key = "sequence.palette"

    private(set) var swatches: [Swatch] = []

    init() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Swatch].self, from: data),
           !decoded.isEmpty {
            swatches = decoded
        } else {
            swatches = DefaultPalette.swatches.map { Swatch(name: $0.name, hex: $0.hex) }
            persist()
        }
    }

    func add(name: String, hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        guard clean.count == 6, !swatches.contains(where: { $0.hex.uppercased() == clean }) else { return }
        let label = name.trimmingCharacters(in: .whitespaces)
        swatches.append(Swatch(name: label.isEmpty ? "Custom" : label, hex: clean))
        persist()
    }

    func remove(_ swatch: Swatch) {
        swatches.removeAll { $0.id == swatch.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(swatches) {
            defaults.set(data, forKey: key)
        }
    }
}
