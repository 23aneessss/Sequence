# Sequence Mobile App - Product Design Specification

**Version:** 1.0  
**Status:** Master Specification Document  
**Purpose:** Definitive engineering anchor for AI agents and human developers

---

## 1. Brand Philosophy & Vision

### 1.1 The "Sequence" Concept
The app name **Sequence** is rooted in the philosophy of interlocking momentum. A habit is not an isolated event; it is a linked chain where every successful day builds the foundation for the next. The system architecture and visual identity must reflect this continuous progression, rhythm, and stability.

### 1.2 Anti-"AI Slop" & "Vibe Coding" Manifesto
Most modern apps suffer from generic UI templates: overused massive dropshadows, excessive glassmorphism, glowing neon gradients on every card, and overly gamified interfaces that degrade user focus. **Sequence rejects these patterns entirely.**

**No Vibe Coding:**  
The codebase must be highly structured, strictly typed, and completely modular. No placeholders, no `// TODO: Implement later` code blocks, and no hand-waving geometry definitions.

**No Visual Noise:**  
Avoid unnecessary decorative elements. Every border, color shift, and motion curve must serve a functional UI or UX purpose.

**iOS Ecosystem Native Integrity:**  
The app must feel like it was built by Apple's premium core design team—deeply integrated with system design patterns, utilizing fluid animations that match the display's native refresh rate (ProMotion 120Hz), and preserving absolute ergonomics.

---

## 2. Color System & Design Tokens

### 2.1 Color Architecture & Dynamic Theme Engine

All colors in Sequence must respond natively to light and dark mode transitions. The following Swift extension provides the authoritative color system that all UI code must import and use. **Do not define static color constants elsewhere.** This is the single source of truth.

```swift
import SwiftUI

struct SequenceColor {
    // Brand Core (Always Static)
    static let navySlate = Color(hex: "303E4A")       // Primary branding anchor
    static let mintTeal = Color(hex: "6BEFBF")        // Success, complete states, momentum
    static let accentTeal = Color(hex: "48A69E")      // Interactive items, active selection
    
    // System Adaptability (Dynamic Light/Dark Tokens)
    static var background: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "0D1117") : UIColor(hex: "FFFFFF")
        })
    }
    
    static var surfacePrimary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "161B22") : UIColor(hex: "F6F8FA")
        })
    }
    
    static var surfaceSecondary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "21262D") : UIColor(hex: "EAEEF2")
        })
    }
    
    static var textPrimary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "E6EDF3") : UIColor(hex: "24292F")
        })
    }
    
    static var textSecondary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "8B949E") : UIColor(hex: "656D76")
        })
    }
    
    static var borderOpaque: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "30363D") : UIColor(hex: "D0D7DE")
        })
    }
}

// Extension to support hex initialization
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(hex, radix: 16) ?? 0
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(hex, radix: 16) ?? 0
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
```

### 2.2 Color Token Reference Table

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `background` | #FFFFFF | #0D1117 | Primary screen background |
| `surfacePrimary` | #F6F8FA | #161B22 | Primary card/elevated surfaces |
| `surfaceSecondary` | #EAEEF2 | #21262D | Secondary surfaces, subtle fills |
| `textPrimary` | #24292F | #E6EDF3 | Primary text content |
| `textSecondary` | #656D76 | #8B949E | Secondary text, metadata |
| `borderOpaque` | #D0D7DE | #30363D | Borders, dividers, outlines |
| `navySlate` | #303E4A | #303E4A | Brand identity (static) |
| `mintTeal` | #6BEFBF | #6BEFBF | Success states (static) |
| `accentTeal` | #48A69E | #48A69E | Interactive elements (static) |

### 2.3 Token Usage Rules

**Rule 1:** Always use `SequenceColor.tokenName` in all SwiftUI views. Never hardcode hex values.

```swift
// ✅ CORRECT
Text("Hello").foregroundColor(SequenceColor.textPrimary)
Rectangle().fill(SequenceColor.surfacePrimary)

// ❌ INCORRECT
Text("Hello").foregroundColor(Color(hex: "24292F"))
Rectangle().fill(Color.white)
```

**Rule 2:** Dynamic tokens (background, surfacePrimary, etc.) automatically adapt to system appearance changes. No additional environment modifiers required.

**Rule 3:** Static brand tokens (navySlate, mintTeal, accentTeal) do not change between light and dark modes. They remain constant by design.

---

## 3. Typography System (Inter / San Francisco System)

The typography must prioritize absolute geometric clarity and legibility. Use tracking (letter-spacing) adjustment to elevate the layout design.

### 3.1 Type Scale

| Element | Font | Weight | Size | Tracking | Color |
|---------|------|--------|------|----------|-------|
| App Title / Branding | Inter / System Sans-Serif | SemiBold | 22pt | tight | textPrimary |
| Section Headers | Inter / System Sans-Serif | Bold | 16pt | -0.24 | textPrimary |
| Habit Title / Core Metric | Inter / System Sans-Serif | Medium | 15pt | — | textPrimary |
| Subtext / Meta Data | Inter / System Sans-Serif | Regular | 12pt | — | textSecondary |

### 3.2 Implementation Notes
- **App Title:** All Caps only
- **Habit Title:** Leading must match 20pt
- **All sizes:** Maintain exact pt values; no deviation

---

## 4. Grid Architecture & Layout Metrics

The interface strictly enforces a **fixed 8pt Grid System**. No arbitrary layout constants are permitted.

### 4.1 Spacing Standards

| Element | Spacing |
|---------|---------|
| Screen Padding (Horizontal Margin) | 16pt |
| Card Internal Padding | 12pt |
| Inner Item Spacing | 8pt |
| Section Vertical Separation | 24pt |

### 4.2 Corner Radii

| Component | Radius |
|-----------|--------|
| Small UI Components (Buttons/Toggles) | 8pt |
| Main Grid Cards / Interactive Blocks | 14pt |
| **Constraint** | Continuous curvature only (`.continuous`) |

---

## 5. Motion Language & Animations (Bespoke SwiftUI Mechanics)

Since there is no external Framer Motion equivalent library in iOS that matches native performance, Sequence utilizes custom extensions of native SwiftUI animation framework capabilities, exploiting spring physics, interpolation phases, and geometric mapping (`matchedGeometryEffect`).

### 5.1 Custom Spring Curve Constants

All standard animations (`.easeInOut`, `.linear`) are **completely banned** for interactive changes. Every single movement must follow engineered physical models:

```swift
extension Animation {
    /// For structural transformations (e.g., expanding a habit card into detailed view)
    static let sequenceStructural = Animation.spring(
        response: 0.38,
        dampingFraction: 0.78,
        blendDuration: 0
    )
    
    /// For micro-interactions (e.g., checking off a sequence step, button presses)
    static let sequenceMicro = Animation.spring(
        response: 0.22,
        dampingFraction: 0.65,
        blendDuration: 0
    )
    
    /// For fluid contextual transitions (e.g., switching filtering tabs)
    static let sequenceFluid = Animation.spring(
        response: 0.42,
        dampingFraction: 0.85,
        blendDuration: 0
    )
}
```

### 5.2 Key Micro-Interactions & Phase Animators

When a user completes a habit, the interaction must feel physically rewarding. The view must trigger a precise phase-based scale/opacity transformation coupled with haptics.

```swift
// Implementation Standard for Sequence Completion Toggle View
struct SequenceCheckmarkButton: View {
    var isCompleted: Bool
    var action: () -> Void
    
    @State private var animateTrigger = false
    
    var body: some View {
        Button(action: {
            // Generate distinct tactile sensation
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.prepare()
            impact.impactOccurred()
            
            action()
            animateTrigger.toggle()
        }) {
            ZStyleCheckmark(isCompleted: isCompleted)
        }
        .buttonStyle(NoOpButtonStyle())
        .sensoryFeedback(.success, trigger: animateTrigger) // iOS 17 Native alternative
        .scaleEffect(animateTrigger ? 0.92 : 1.0)
        .animation(.sequenceMicro, value: animateTrigger)
    }
}
```

### 5.3 Advanced Interface Transitions: matchedGeometryEffect

When selecting a habit to see its detailed continuity grid, the card must not push onto a traditional navigation stack. Instead, it transforms inline using a coordinated spatial transition:

1. The layout system caches the layout identifier of the individual habit card.
2. When clicked, the parent view hides the grid and displays the Detail Modal, mapping components seamlessly across the frame via Namespace tracking.
3. **Rule for AI Agent:** Never drop contextual orientation. The background sequence lines must remain continuous during the frame interpolation.

---

## 6. Ergonomics & Interface Layout Patterns

### 6.1 Thumb-Zone Optimization

- **Primary Action Zone:** Lower 60% of viewport
- **Navigation:** Avoid top-left back buttons where possible. Implement native interactive sheet dismissals via intuitive swipe-down gestures, or place clear secondary floating-action controllers reachable by thumb anchors.
- **Creation Action:** The habit sequence builder must open inside an interactive dynamic bottom sheet that expands gracefully using custom fraction-detents:
  ```swift
  .presentationDetents([.fraction(0.6), .large])
  ```

### 6.2 Empty & Interactive Loading States

**Zero-State Minimalism:**  
When no habits exist in a sequence, do not display clip-art vectors or empty illustrations. Display precise typography indicating current intent, bounded by a clean dashed structural box utilizing the exact border token `#D0D7DE` / `#30363D`.

**Shimmer (Skeleton Loading):**  
Linear gradients blending smoothly across backgrounds using continuous animation phase parameters. Never block the interface with an intrusive blocking modal spinner.

---

## 7. Strict Execution Rules for AI Coding Agents

Every AI component generation or architectural decision must obey these non-negotiable software engineering rules.

### 7.1 No "Vibe Coding" Boilerplate

**Strict Typing:**  
Never use un-typed dictionaries or implicit optional wrapping (`!`). Use robust Swift optional unwrapping (`if let`, `guard let`) or provide safe default fallbacks.

**View Architecture:**  
All views must separate state tracking from rendering code. Use the `@Observable` pattern (iOS 17+) or structured standard `ObservableObject` ViewModels.

**No Monolithic Views:**  
If a view body extends past 120 lines of code, you are violating protocol. Extract internal architectural layouts into standalone localized layout computations or structural private subviews.

### 7.2 Performance & State Management Realism

**Lazy Collections:**  
For habit sequences, historical logs, or tracking structures, use `LazyVStack` and `LazyHGrid`. Never initialize standard memory-heavy `VStack` contexts inside scroll containers.

**State Localization:**  
Never bubble up view state updates globally unless explicitly required for underlying persistence layers. Keep button scaling states localized to component frames.

**ID Stability:**  
Always explicitly declare unique identifiers (`id: \.id` or matching UUID properties) inside dynamic loops to ensure the SwiftUI rendering pipeline handles geometric mutations efficiently without dropping frames.

### 7.3 Technical Code Blueprint for Persistence & Architecture

The coding agent must conform to this core repository pattern skeleton:

```swift
import Foundation
import SwiftData

@Observable
final class SequenceRepository {
    private var modelContext: ModelContext
    public var activeSequences: [HabitSequence] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchSequences()
    }
    
    func fetchSequences() {
        let descriptor = FetchDescriptor<HabitSequence>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            self.activeSequences = try modelContext.fetch(descriptor)
        } catch {
            print("Sequence Database Error: Failed to fetch active models: \(error)")
        }
    }
    
    func toggleHabitsCompletion(for sequence: HabitSequence, on date: Date) {
        // Enforce transaction safety across the application stack
        sequence.mutateCompletionState(for: date)
        try? modelContext.save()
    }
}
```

---

## 8. Layout Reference Specifications

### 8.1 The Main Dashboard Layout

**Header:**  
- Clean left-aligned brand title text (SEQUENCE)
- Height: 44pt
- Right element: Minimalistic profile/calendar overview indicator

**Horizontal Continuity Grid:**  
A 7-day gliding window tracking continuous streak velocity across all combined habits.

**Active Sequences List:**  
A minimalist stack of native habit blocks. Each card features:
- Clean left-aligned custom progress track
- Title and Current Sequence Streak count (e.g., 14d)
- Rapid-action mechanical action button for instant completion logging

### 8.2 The Creation Suite Layout

**Input:**  
Simple text field with no persistent border line—only a background surface shift tracking active focus state.

**Rhythm Matrix Selection:**  
Custom toggle blocks grouping intervals:
- Daily
- Custom Interval Sequences
- Specific Anchors

**Action Control:**  
Full width interactive confirmation button utilizing `SequenceColor.accentTeal` paired with a light spring transformation scale interaction.

---

## 9. Compliance Checklist

- [ ] All colors use semantic tokens, never raw hex
- [ ] Typography strictly follows type scale table
- [ ] All spacing follows 8pt grid system
- [ ] All animations use custom spring curves (no `.easeInOut`)
- [ ] Views are modular (no view body > 120 lines)
- [ ] All optionals use safe unwrapping
- [ ] Dynamic loops include explicit ID declarations
- [ ] Lazy collections used for large data sets
- [ ] Empty states use typography only, no illustrations
- [ ] Primary actions are in lower 60% of screen

---

**END OF SPECIFICATION**

Any code generated for this mobile app that deviates from the grid, color, or code modularity constants listed above is **explicitly incorrect**. Use this as your root execution prompt for all engineering segments.
