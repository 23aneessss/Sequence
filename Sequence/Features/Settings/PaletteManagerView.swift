//
//  PaletteManagerView.swift
//  Sequence
//
//  Manage the personal colour palette. Reference: app_concept.md §9.3.
//  Add via a system HSB picker; deletion is blocked for colours in use by an
//  active (non-archived) habit.
//

import SwiftUI

struct PaletteManagerView: View {
    @Environment(PaletteStore.self) private var palette
    @Environment(SequenceRepository.self) private var repo

    @State private var newColor = Color(hex: DefaultPalette.defaultHex)
    @State private var newName = ""
    @State private var blockedSwatch: PaletteStore.Swatch?

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: SequenceSpacing.item)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                Text("Color Palette").sequenceStyle(.appTitle)
                grid
                addSection
            }
            .padding(SequenceSpacing.screenMargin)
        }
        .background(SequenceColor.background.ignoresSafeArea())
        .alert("Color in use", isPresented: Binding(get: { blockedSwatch != nil }, set: { if !$0 { blockedSwatch = nil } })) {
            Button("OK", role: .cancel) { blockedSwatch = nil }
        } message: {
            Text(blockedMessage)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: SequenceSpacing.item) {
            ForEach(palette.swatches) { swatch in
                VStack(spacing: SequenceSpacing.half) {
                    ZStack {
                        RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                            .fill(Color(hex: swatch.hex)).frame(height: 56)
                        Button { attemptDelete(swatch) } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .offset(x: 32, y: -16)
                    }
                    Text(swatch.name).sequenceTextStyle(.subtext).lineLimit(1).minimumScaleFactor(0.7)
                }
            }
        }
    }

    private var addSection: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Add a color").sequenceTextStyle(.sectionHeader)
            ColorPicker("Pick a color", selection: $newColor, supportsOpacity: false)
                .sequenceTextStyle(.habitTitle)
            TextField("Name", text: $newName)
                .sequenceTextStyle(.habitTitle)
                .padding(SequenceSpacing.cardPadding)
                .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                    .fill(SequenceColor.surfaceSecondary))
            PrimaryButton(title: "Add color") {
                palette.add(name: newName, hex: newColor.hexString)
                newName = ""
            }
        }
    }

    private func attemptDelete(_ swatch: PaletteStore.Swatch) {
        let inUse = repo.allHabits(includeArchived: false)
            .contains { $0.colorHex.uppercased() == swatch.hex.uppercased() }
        if inUse { blockedSwatch = swatch } else { palette.remove(swatch) }
    }

    private var blockedMessage: String {
        guard let swatch = blockedSwatch else { return "" }
        let users = repo.allHabits(includeArchived: false)
            .filter { $0.colorHex.uppercased() == swatch.hex.uppercased() }
            .map(\.name).joined(separator: ", ")
        return "“\(swatch.name)” is used by: \(users). Reassign those habits first."
    }
}
