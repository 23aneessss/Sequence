# Sequence — Build Plan & Coding Path

**Version:** 1.0
**Status:** Pre-Development Roadmap
**Sources of truth:** [`app_concept.md`](./app_concept.md) (product north star) · [`product_design.md`](./product_design.md) (visual + code architecture law)
**Platform:** iOS 17+ · Swift 5.9+ · SwiftUI · SwiftData

> This document is the **coding path**. It does not redefine product or design decisions — those live in the two source docs. It sequences *what gets built, in what order, with what dependencies, and how we know each step is done.* Read the two source docs before each phase; this plan tells you which sections apply when.

---

## 0. Guiding Constraints (apply to every phase)

These are non-negotiable and pulled from `product_design.md` §7 and §9. Every PR/commit is checked against them:

- **Colors:** only `SequenceColor.*` tokens — never raw hex in views (`product_design.md` §2.3).
- **Spacing:** strict 8pt grid — 16 / 12 / 8 / 24 (`product_design.md` §4.1).
- **Corner radii:** 8pt small, 14pt cards, always `.continuous` (`product_design.md` §4.2).
- **Animation:** only `.sequenceStructural` / `.sequenceMicro` / `.sequenceFluid`. `.easeInOut` and `.linear` are banned for interactive change (`product_design.md` §5.1).
- **View size:** no view `body` > 120 lines — extract subviews/computed layouts (`product_design.md` §7.1).
- **Typing:** no force-unwraps (`!`), no untyped dictionaries; `guard let` / `if let` / safe defaults (`product_design.md` §7.1).
- **State:** `@Observable` (iOS 17) view models; localize component state; never bubble globally without reason (`product_design.md` §7.2).
- **Lazy collections:** `LazyVStack` / `LazyHGrid` for all scrollable/large data; explicit `id:` in every dynamic loop (`product_design.md` §7.2).
- **Empty states:** typography + dashed `borderOpaque` box only — no illustrations (`product_design.md` §6.2).
- **Primary actions** live in the lower 60% of the viewport (`product_design.md` §6.1).

A `Compliance` pass closes every phase (see §9 checklist in `product_design.md`).

---

## 1. Naming Convention (RESOLVED ✅)

The two docs used different names for the central model. **Decided by owner:** "Sequence" is the **product/app name only** — not a code-model name.

| Concern | Name to use | Notes |
|---|---|---|
| App / product | **Sequence** | Display name, bundle, branding only |
| Habit data model | **`Habit`** | `@Model`, full schema from `app_concept.md` §10.2 |
| Daily log entry | **`HabitLog`** | `@Model` |
| Task data model | **`DailyTask`** | `@Model` |
| Data / aggregation layer | **`SequenceRepository`** | Keeps "Sequence" as a *layer* name, not a model |
| Contribution graph | **"Sequence Graph"** | Product term in UI, backed by `ContributionGraphView` |

The `HabitSequence` naming and the `product_design.md` §7.3 repository skeleton are treated as **pattern illustrations**, not literal API. The reserved word "Sequence" is used for the app, the repository layer, and the graph concept — never as a `@Model` class name.

---

## 2. Target Architecture & Folder Layout

A feature-folder structure under one app target. Created in Phase 1.

```
Sequence/
├── App/
│   ├── SequenceApp.swift              // @main, ModelContainer, root switch (splash/onboarding/main)
│   └── AppRouter.swift                // launch-state routing (onboarded? → main : onboarding)
│
├── DesignSystem/                      // BUILD FIRST — nothing renders without this
│   ├── SequenceColor.swift            // tokens + Color/UIColor(hex:) (product_design.md §2.1)
│   ├── Animations.swift               // .sequenceStructural/.sequenceMicro/.sequenceFluid (§5.1)
│   ├── Typography.swift               // type scale view modifiers (§3.1)
│   ├── Spacing.swift                  // 8pt grid constants (§4.1)
│   └── Components/                     // reusable primitives
│       ├── SequenceCheckmarkButton.swift   // (product_design.md §5.2)
│       ├── PrimaryButton.swift             // accentTeal full-width spring button
│       ├── DashedEmptyState.swift          // typography-only empty state (§6.2)
│       └── ShimmerView.swift               // skeleton loading (§6.2)
│
├── Models/
│   ├── Habit.swift                    // @Model (app_concept.md §10.2)
│   ├── HabitLog.swift                 // @Model
│   ├── DailyTask.swift                // @Model
│   └── Enums.swift                    // HabitType, HabitSchedule, TaskPriority
│
├── Data/
│   ├── SequenceRepository.swift       // @Observable; fetch/aggregate/mutate (product_design.md §7.3)
│   ├── IntensityEngine.swift          // value → level 0–5 mapping (concept §2.2, §3)
│   ├── StreakEngine.swift             // current/best/active-days (concept §2.4, §5.2)
│   ├── StatsEngine.swift              // momentum, seriousness, per-habit metrics (concept §5)
│   ├── ColorScaleEngine.swift         // base color → 6-level HSB scale (concept §9.3)
│   └── DataExporter.swift             // JSON export (concept §10.4)
│
├── Features/
│   ├── Graph/                         // THE core mechanic (concept §2)
│   │   ├── ContributionGraphView.swift
│   │   ├── GraphCell.swift / GraphCellView.swift
│   │   ├── MiniSparklineView.swift    // 7-day card sparkline
│   │   └── CellTooltipView.swift
│   ├── Today/                         // Tab 1 (concept §8.1)
│   │   ├── TodayView.swift
│   │   ├── TodayViewModel.swift
│   │   ├── HabitCardView.swift
│   │   └── ContinuityStripView.swift  // 7-day window
│   ├── HabitDetail/                   // matchedGeometry expand (concept §5.2, design §5.3)
│   ├── HabitCreation/                 // bottom sheet flow (concept §3.3)
│   ├── Tasks/                         // Tab 2 (concept §4)
│   ├── Stats/                         // Tab 3 (concept §5)
│   ├── Settings/                      // Tab 4 + color palette mgr (concept §8.1, §9)
│   └── Onboarding/                    // splash + 5 screens + coach marks (concept §7)
│
├── Notifications/
│   ├── NotificationManager.swift      // UNUserNotificationCenter scheduling (concept §6)
│   └── BackgroundTaskManager.swift    // BGAppRefreshTask (concept §6.2)
│
└── Resources/
    └── Assets.xcassets                // logo/icons provided separately (concept p.706)
```

---

## 3. Phased Build Sequence

Dependency-ordered. Each phase ships something verifiable. **Do not start a phase before its predecessors compile and pass their acceptance gate.**

### Phase 1 — Foundation (Design System + Project)
**Depends on:** naming decision (§1)
**Build:**
- Xcode project, iOS 17 target, SwiftData enabled, folder structure (§2).
- `SequenceColor`, hex initializers, full token set (`product_design.md` §2.1).
- `Animation` extensions (`product_design.md` §5.1).
- Typography modifiers + spacing constants.
- Core reusable components: `SequenceCheckmarkButton`, `PrimaryButton`, `DashedEmptyState`, `ShimmerView`.

**Acceptance gate:** A throwaway preview screen renders all tokens in light + dark, all three spring animations fire on a test button, checkmark button gives haptic + scale pulse. No raw hex anywhere.

---

### Phase 2 — Data Layer (Models + Repository, no UI)
**Depends on:** Phase 1
**Build:**
- `@Model` types: `Habit`, `HabitLog`, `DailyTask` + enums (`app_concept.md` §10.2).
- `ModelContainer` wiring in `SequenceApp`.
- `SequenceRepository` (`@Observable`): fetch, create, update, archive, log, toggle-task, save (`product_design.md` §7.3).
- Date normalization helper (logs → midnight local).

**Acceptance gate:** Unit tests (or a debug harness) create habits, write logs, fetch them back, archive — all persisting across relaunch.

---

### Phase 3 — Core Engines (the brains, pure logic)
**Depends on:** Phase 2
**Build:**
- `IntensityEngine`: `intensityLevel(for:on:)` → 0–5 per habit type, honoring user thresholds (`app_concept.md` §2.2, §3.1, §4.2 for tasks).
- `StreakEngine`: current streak, best streak, total active days, streak threshold setting (`app_concept.md` §2.4, §9.4).
- `StatsEngine`: momentum score, seriousness index, all per-habit metrics + trend arrow (`app_concept.md` §5).
- `ColorScaleEngine`: base color → 6-level HSB scale (`app_concept.md` §9.3).

**Acceptance gate:** Unit tests cover binary/counted/timed level mapping at every threshold boundary, streak across gaps and midnight, seriousness/momentum formulas, and color-scale generation for ≥3 base colors. **This phase is test-heavy by design — the graph is only as trustworthy as these.**

---

### Phase 4 — The Contribution Graph (the core mechanic)
**Depends on:** Phase 3
**Build:**
- `GraphCell` model + `graphCells(for:year:)` in repository (`app_concept.md` §10.3).
- `ContributionGraphView` with `LazyHGrid`, 365-day grid, week columns, color mapping from `IntensityEngine` + `ColorScaleEngine`.
- Interactions: tap → tooltip, long-press → quick-edit, pinch → zoom levels, swipe → year nav (`app_concept.md` §2.3).
- Staggered column reveal animation (`app_concept.md` §11.1).
- `MiniSparklineView` (7-day).
- Streak bar (`app_concept.md` §2.4).

**Acceptance gate:** Graph renders a year of seeded data correctly in both modes, all four interactions work, staggered reveal uses `.sequenceFluid`, scrolling stays at 120Hz (lazy + stable ids).

---

### Phase 5 — Today Dashboard + Habit CRUD
**Depends on:** Phase 4
**Build:**
- `TodayView`: header streak summary, `ContinuityStripView` (7-day), scrollable habit cards, FAB (`app_concept.md` §8.1).
- `HabitCardView` (`app_concept.md` §3.2) with type-appropriate log control + progress bar.
- Logging: binary tap, counted `+`/bulk numeric, timed timer w/ background continuation (`app_concept.md` §3.1).
- Logging feedback: haptic, button pulse, live sparkline update, milestone particle burst, header bounce (`app_concept.md` §11.2).
- Streak-break visual treatment (`app_concept.md` §11.3).
- Habit Creation bottom sheet, 7-step flow (`app_concept.md` §3.3).
- Habit Detail via `matchedGeometryEffect` (`app_concept.md` §5.2, `product_design.md` §5.3).

**Acceptance gate:** Full create → log → see-graph-update loop works for all three habit types; detail expand/collapse is a single matched-geometry transition (no nav push); empty state shows when no habits.

---

### Phase 6 — Daily Tasks Module
**Depends on:** Phase 4 (graph) + Phase 5 (patterns)
**Build:**
- `DailyTask` board (Tab 2), task cards, checkbox toggle, time anchor, priority badge (`app_concept.md` §4.3).
- Task completion progress bar.
- Task Contribution Graph with completion-rate → intensity mapping incl. Perfect Day treatment (`app_concept.md` §4.2).
- Template tasks, rollover prompt, archive feeding the graph (`app_concept.md` §4.4).
- Perfect Day celebration banner (`app_concept.md` §11.4).

**Acceptance gate:** Setting/completing tasks updates today's task-graph cell to the correct level; 100% triggers Perfect Day pulse + banner; template + rollover behaviors work across a simulated day boundary.

---

### Phase 7 — Statistics & Analytics
**Depends on:** Phase 3 (engines) + Phase 4 (graph)
**Build:**
- Momentum Dashboard (Tab 3): macro momentum score + 30-day mini grid (`app_concept.md` §5.1).
- Seriousness Index circular gauge.
- Per-habit stats cards w/ full metric table + 365-day graph + year nav (`app_concept.md` §5.2).
- Yearly Review "Year in Sequence" card → image export + share sheet (`app_concept.md` §5.3).
- Skeleton/shimmer loading on stats screen.

**Acceptance gate:** Every metric in `app_concept.md` §5.2 displays and matches engine output; yearly review renders to a shareable image.

---

### Phase 8 — Settings & Customization Engine
**Depends on:** Phase 1 (tokens) + Phase 2 (persistence)
**Build:**
- Settings (Tab 4): appearance, week start, graph direction, streak threshold, default reminder time, reset coach marks, about (`app_concept.md` §8.1, §9.4).
- Color Palette manager: 6 defaults, HSB picker + hex input add, in-use deletion guard (`app_concept.md` §9.3).
- Data export flow → JSON file (`app_concept.md` §10.4).

**Acceptance gate:** Changing week start / graph direction / appearance re-renders graphs correctly; custom color generates a valid 6-level scale and is selectable in habit creation; export produces valid JSON matching the §10.4 schema.

---

### Phase 9 — Notifications & Background
**Depends on:** Phase 2 (data) + Phase 5 (habits exist to remind on)
**Build:**
- `NotificationManager`: habit reminder, streak-at-risk (21:00 logic), morning task summary, milestone celebration (`app_concept.md` §6.1).
- Rich notification actions: `Log Now` / `Snooze` with background log handler (`app_concept.md` §6.1, §6.2).
- `BackgroundTaskManager`: `BGAppRefreshTask` — reschedule next 64, midnight streak refresh, pending-action processing (`app_concept.md` §6.2).
- DND window respect; permission requested in onboarding, not launch (`app_concept.md` §6.3).

**Acceptance gate:** All four notification types schedule and fire on device; `Log Now` writes a log without opening the app; streak-at-risk respects DND; only 64-notification window scheduled at once.

---

### Phase 10 — Onboarding & First Launch
**Depends on:** Phases 4, 5, 9 (it stitches real features together)
**Build:**
- Splash (1.2s spring reveal → dissolve) (`app_concept.md` §7.1).
- 5-screen `TabView(.page)` onboarding; Screen 3 creates a **real** first habit; Screen 4 triggers real notification permission (`app_concept.md` §7.2).
- `matchedGeometryEffect` from final CTA into first habit card.
- Coach marks (4, sequential, `UserDefaults`-gated) (`app_concept.md` §7.3).

**Acceptance gate:** Fresh install → splash → 5 screens → main app with the habit created during onboarding already present; coach marks show once and never again; "Maybe later" path works.

---

### Phase 11 — Polish, Compliance & Release Readiness
**Depends on:** all prior phases
**Build / verify:**
- Run full `product_design.md` §9 + `app_concept.md` §12 checklists.
- Dark mode audit on every screen.
- Confirm no view body > 120 lines; lazy collections everywhere; haptics on all primary actions.
- Empty + skeleton states on all list/stat screens.
- Drop in real assets (logo/icons) into `Assets.xcassets`.
- Performance pass at 120Hz; no dropped frames on graph scroll/zoom.

**Acceptance gate:** Both source-doc checklists fully green; no banned animation curve, no raw hex, no force-unwrap in the codebase.

---

## 4. Critical Path & Parallelization

```
P1 Foundation ─► P2 Data ─► P3 Engines ─► P4 Graph ─┬─► P5 Today/CRUD ─► P6 Tasks
                                                     ├─► P7 Stats
                                                     └─► P9 Notifications (also needs P5)
P8 Settings can start after P2 (needs P4 to fully verify graph-direction/week-start)
P10 Onboarding requires P4 + P5 + P9
P11 closes everything
```

- **Hard serial spine:** P1 → P2 → P3 → P4 → P5. Nothing meaningful renders or is trustworthy before P4.
- **Parallelizable after P4/P5:** Stats (P7), Settings (P8), Tasks (P6) are largely independent.
- **Highest-risk / build-early-attention:** P3 engines (correctness) and P4 graph (performance + the entire product thesis). Over-invest in tests here.

---

## 5. Per-Phase Definition of Done

A phase is done only when **all** hold:
1. Compiles clean, zero warnings.
2. Its acceptance gate (above) passes.
3. Phase-relevant items in `product_design.md` §9 and `app_concept.md` §12 are checked.
4. New logic has unit tests (engines, repository, formulas — non-negotiable for P2/P3/P7).
5. Light + dark verified for any UI shipped in the phase.

---

## 6. Open Questions for Owner (resolve before coding)

1. ~~**Model naming**~~ — **RESOLVED** (§1): app = "Sequence"; models = `Habit`/`HabitLog`/`DailyTask`; layer = `SequenceRepository`.
2. **Minimum iOS version** — docs imply iOS 17 (SwiftData, `@Observable`, `.sensoryFeedback`). Will default to **iOS 17** unless told otherwise.
3. **Timed habit background timer** — true background-running timer vs. timestamp-diff on return. iOS constrains true background execution, so will default to **timestamp-diff on return** unless told otherwise. Affects Phase 5.
4. **Assets** — logo/icons delivered separately (`app_concept.md` p.706); needed before Phase 10/11.
5. **Cloud sync** — concept says local-only v1.0; will assume **no CloudKit** unless told otherwise.

> For items 2, 3, 5 I'll proceed with the sensible defaults noted above unless you say otherwise — none of them block starting Phase 1.

---

## 7. How to Use This Plan

- Build strictly in phase order along the serial spine; parallel branches only after their gate dependency is met.
- At the **start** of each phase, re-read the cited sections of the two source docs.
- At the **end** of each phase, run §5 Definition of Done before moving on.
- This file tracks *sequencing*; it never overrides `app_concept.md` (product) or `product_design.md` (visual/architecture law). On any conflict, those win and this plan is corrected.

---

**END OF BUILD PLAN** — Awaiting owner go-ahead and resolution of §6 open questions before Phase 1.
</content>
</invoke>
