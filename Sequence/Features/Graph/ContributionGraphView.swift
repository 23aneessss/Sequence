//
//  ContributionGraphView.swift
//  Sequence
//
//  The Sequence graph — a GitHub-style 365-day contribution grid.
//  Reference: app_concept.md §2 (mechanic), §11.1 (staggered reveal).
//
//  Interactions: tap a cell → tooltip; long-press → edit callback;
//  pinch → cycle zoom (year / 6-month / 3-month). The grid is column-major
//  and starts scrolled to the most recent week.
//

import SwiftUI

/// Zoom presets for the graph. Reference: app_concept.md §2.3.
enum GraphZoom: CaseIterable {
    case year, sixMonth, threeMonth

    var dayCount: Int {
        switch self {
        case .year:       return 365
        case .sixMonth:   return 182
        case .threeMonth: return 91
        }
    }
    var cellSize: CGFloat {
        switch self {
        case .year:       return 11
        case .sixMonth:   return 15
        case .threeMonth: return 22
        }
    }
    var spacing: CGFloat {
        switch self {
        case .year:       return 3
        case .sixMonth:   return 4
        case .threeMonth: return 5
        }
    }
    var zoomedIn: GraphZoom { self == .year ? .sixMonth : .threeMonth }
    var zoomedOut: GraphZoom { self == .threeMonth ? .sixMonth : .year }
}

struct ContributionGraphView: View {
    let habit: Habit
    var weekStartsOn: Int = 1
    var onLongPressCell: ((GraphCell) -> Void)? = nil

    @State private var zoom: GraphZoom = .year
    @State private var selected: GraphCell?
    @State private var appeared = false

    private var builder: ContributionGraphBuilder {
        ContributionGraphBuilder(weekStartsOn: weekStartsOn)
    }
    private var cells: [GraphCell] {
        builder.cells(for: habit, dayCount: zoom.dayCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            if let selected {
                tooltip(for: selected)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            HStack(alignment: .top, spacing: SequenceSpacing.half + 2) {
                weekdayLabels
                gridScrollView
            }
        }
        .gesture(zoomGesture)
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: - Grid

    private var gridScrollView: some View {
        let columns = builder.columnCount(for: cells)
        let rows = Array(repeating: GridItem(.fixed(zoom.cellSize), spacing: zoom.spacing),
                         count: builder.rowCount)
        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: zoom.spacing + 2) {
                monthLabelsRow(columns: columns)
                LazyHGrid(rows: rows, spacing: zoom.spacing) {
                    ForEach(Array(cells.enumerated()), id: \.element.id) { index, cell in
                        cellView(cell, column: index / builder.rowCount)
                    }
                }
            }
            .padding(.trailing, SequenceSpacing.half)
        }
        .defaultScrollAnchor(.trailing)
    }

    private func cellView(_ cell: GraphCell, column: Int) -> some View {
        GraphCellView(cell: cell, colorHex: habit.colorHex,
                      size: zoom.cellSize, isSelected: selected?.date == cell.date)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.6)
            .animation(.sequenceFluid.delay(Double(column) * 0.02), value: appeared)
            .contentShape(Rectangle())
            .onTapGesture {
                guard cell.isInRange else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.sequenceMicro) {
                    selected = (selected?.date == cell.date) ? nil : cell
                }
            }
            .onLongPressGesture {
                guard cell.isInRange else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onLongPressCell?(cell)
            }
    }

    // MARK: - Labels

    private var weekdayLabels: some View {
        let symbols = Calendar.sequence.shortWeekdaySymbols
        return VStack(spacing: zoom.spacing) {
            ForEach(0..<builder.rowCount, id: \.self) { row in
                let weekday = ((weekStartsOn - 1 + row) % 7)
                Text(row % 2 == 1 ? String(symbols[weekday].prefix(3)) : "")
                    .sequenceTextStyle(.subtext)
                    .frame(width: 26, height: zoom.cellSize, alignment: .leading)
            }
        }
        .padding(.top, zoom.cellSize + zoom.spacing + 2) // align below month-label row
    }

    private func monthLabelsRow(columns: Int) -> some View {
        let segments = monthSegments(columns: columns)
        let columnWidth = zoom.cellSize + zoom.spacing
        return HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                Text(segment.label)
                    .sequenceTextStyle(.subtext)
                    .frame(width: CGFloat(segment.span) * columnWidth, alignment: .leading)
            }
        }
        .frame(height: zoom.cellSize)
    }

    /// Groups columns by calendar month so each month gets a slot wide enough for
    /// its abbreviation (avoids per-column truncation). A month's label is shown
    /// only if its segment is wide enough to fit; otherwise the slot is blank.
    private func monthSegments(columns: Int) -> [(label: String, span: Int)] {
        guard columns > 0 else { return [] }
        let calendar = Calendar.sequence

        func month(ofColumn col: Int) -> Int? {
            let slice = cells[(col * builder.rowCount)..<min((col + 1) * builder.rowCount, cells.count)]
            return slice.first { $0.isInRange }.map { calendar.component(.month, from: $0.date) }
        }

        var segments: [(label: String, span: Int)] = []
        var currentMonth = month(ofColumn: 0)
        var runStart = 0
        for col in 1...columns {
            let m = col < columns ? month(ofColumn: col) : nil
            if m != currentMonth || col == columns {
                let span = col - runStart
                let label = (currentMonth.map { span >= 3 ? String(calendar.shortMonthSymbols[$0 - 1].prefix(3)) : "" }) ?? ""
                segments.append((label, span))
                currentMonth = m
                runStart = col
            }
        }
        return segments
    }

    // MARK: - Tooltip

    private func tooltip(for cell: GraphCell) -> some View {
        HStack {
            CellTooltipView(cell: cell, unit: habit.unit)
            Spacer(minLength: 0)
        }
        .background(
            RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                .fill(SequenceColor.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .strokeBorder(SequenceColor.borderOpaque, lineWidth: 1)
                )
        )
    }

    // MARK: - Zoom

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onEnded { scale in
                withAnimation(.sequenceStructural) {
                    if scale > 1.2 { zoom = zoom.zoomedIn }
                    else if scale < 0.8 { zoom = zoom.zoomedOut }
                }
            }
    }
}
