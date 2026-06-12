//
//  DesignSystemTests.swift
//  SequenceTests
//
//  Phase 1 foundation tests: hex parsing correctness and token presence.
//

import XCTest
import SwiftUI
@testable import Sequence

final class DesignSystemTests: XCTestCase {

    /// Hex parsing must produce the exact RGB components, with or without `#`,
    /// and must fall back safely (to black) on malformed input rather than crash.
    func testUIColorHexParsing() {
        let teal = UIColor(hex: "48A69E")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        teal.getRed(&r, green: &g, blue: &b, alpha: &a)

        XCTAssertEqual(r, 0x48 / 255.0, accuracy: 0.001)
        XCTAssertEqual(g, 0xA6 / 255.0, accuracy: 0.001)
        XCTAssertEqual(b, 0x9E / 255.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func testHexParsingIgnoresHashPrefix() {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(hex: "#6BEFBF").getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(hex: "6BEFBF").getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        XCTAssertEqual(r1, r2, accuracy: 0.001)
        XCTAssertEqual(g1, g2, accuracy: 0.001)
        XCTAssertEqual(b1, b2, accuracy: 0.001)
    }

    func testMalformedHexFallsBackToBlack() {
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 0
        UIColor(hex: "ZZZ").getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0, accuracy: 0.001)
        XCTAssertEqual(g, 0, accuracy: 0.001)
        XCTAssertEqual(b, 0, accuracy: 0.001)
    }

    /// Spacing tokens must hold the exact 8pt-grid values from product_design.md §4.1.
    func testSpacingGridValues() {
        XCTAssertEqual(SequenceSpacing.screenMargin, 16)
        XCTAssertEqual(SequenceSpacing.cardPadding, 12)
        XCTAssertEqual(SequenceSpacing.item, 8)
        XCTAssertEqual(SequenceSpacing.section, 24)
        XCTAssertEqual(SequenceRadius.small, 8)
        XCTAssertEqual(SequenceRadius.card, 14)
    }
}
