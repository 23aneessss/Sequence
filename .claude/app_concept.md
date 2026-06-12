# Sequence — App Concept Document

**Version:** 1.0  
**Platform:** iOS (Swift / SwiftUI)  
**Status:** Production-Ready Specification  
**Design Reference:** `product_design.md`

---

## Table of Contents

1. [App Vision & Core Philosophy](#1-app-vision--core-philosophy)
2. [The Core Mechanic — The Sequence Graph](#2-the-core-mechanic--the-sequence-graph)
3. [Habit System — Types & Customization](#3-habit-system--types--customization)
4. [Daily Tasks Module](#4-daily-tasks-module)
5. [Statistics & Analytics Module](#5-statistics--analytics-module)
6. [Notification System](#6-notification-system)
7. [Onboarding & First Launch Flow](#7-onboarding--first-launch-flow)
8. [App Screen Architecture](#8-app-screen-architecture)
9. [Customization Engine](#9-customization-engine)
10. [Data Architecture](#10-data-architecture)
11. [Animation & Interaction Philosophy](#11-animation--interaction-philosophy)
12. [Technical Implementation Checklist](#12-technical-implementation-checklist)

---

## 1. App Vision & Core Philosophy

### 1.1 The Problem with Existing Habit Trackers

Every habit tracker on the App Store suffers from the same fundamental flaw: **the feedback loop is too weak.** Checking a box and seeing a number increment by one does not create genuine emotional investment. Users abandon these apps within two weeks because there's no visual representation of momentum — no visceral, daily proof that their consistency is building something.

### 1.2 The Insight — GitHub as a Behavioral Design Model

The **GitHub contribution graph** is arguably the most effective behavioral engagement system in the history of productivity software. Millions of developers open GitHub every single morning — not because they have to, but because they are emotionally compelled to maintain the green chain. The fear of breaking a streak, the satisfaction of a dense column of dark green squares, and the long-term visibility of months of committed work all combine to produce a feedback loop of extraordinary power.

**Sequence borrows this mechanic entirely and applies it to the domain of personal habits.**

### 1.3 The Core Promise

> *"Your habits, visualized as living proof of who you're becoming."*

Every habit the user tracks in Sequence generates its own contribution graph — a scrollable, color-coded historical record of effort. The user is not just checking boxes. They are **building a visual identity** that is entirely unique to their consistency.

### 1.4 Who This App Is For

- Developers and technical users already conditioned by GitHub's visual language
- Productivity-focused individuals who care deeply about data and self-measurement
- Anyone who has tried and abandoned traditional habit trackers due to lack of motivation
- People who want **full control** — not a pre-defined system imposed by the app

---

## 2. The Core Mechanic — The Sequence Graph

### 2.1 What Is the Sequence Graph

The Sequence Graph is a **365-day rolling contribution grid** displayed for each individual habit. It is a direct adaptation of the GitHub contribution graph with meaningful extensions tailored to personal habit tracking.

Each **cell** in the graph represents **one day**. The grid reads left to right, week by week, with the most recent week on the right (or optionally, on the left — user-configurable).

### 2.2 Color Intensity System

The Sequence Graph uses a **5-level intensity scale** per habit. The exact color for each level is set by the user, but the intensity structure is fixed:

| Level | Meaning | GitHub Equivalent |
|-------|---------|-------------------|
| `0` — Empty | No activity recorded | Gray / Off |
| `1` — Minimal | Activity started, threshold not met | Very light tint |
| `2` — Low | Partial completion | Light tint |
| `3` — Medium | Standard completion | Medium tint |
| `4` — Full | Full target met | Base color |
| `5` — Overachieved | Exceeded daily target | Darkest / richest tint |

For **single-completion habits** (e.g., "Read for 30 minutes"), only levels 0 and 4 are used — empty or complete. For **multi-completion habits** (e.g., "Do 100 push-ups"), all 6 levels are activated based on the user-defined thresholds.

### 2.3 Interaction with the Graph

- **Tap a cell** → Shows a tooltip/popover with the exact date, completion count, and time of last log for that day
- **Long-press a cell** → Opens a quick-edit sheet to manually adjust a past day's entry
- **Pinch to zoom** → Transitions between 1-year view, 6-month view, and 3-month zoomed view
- **Swipe left/right on the graph** → Navigates to older years (historical archive)

### 2.4 The Streak Indicator

Below or above each graph, a **streak bar** shows:
- **Current Streak:** Consecutive days with at least Level 1 activity
- **Best Streak Ever:** Personal record for this habit
- **Total Active Days:** Lifetime count of days with any activity

The streak count increments at midnight local time and integrates with the notification system.

---

## 3. Habit System — Types & Customization

### 3.1 Habit Types

**Type A — Binary Habit (Once per Day)**  
A habit that is either done or not done. No partial credit.

Examples: *Take vitamins, Make bed, Meditate (at least once)*

- Graph display: 2 states only (empty / full color)
- Completion: Single tap on the checkmark → immediate full completion
- Undo: Long-press on completed state within the same day

---

**Type B — Counted Habit (Repeating / Quantified)**  
A habit with a quantified target that can be exceeded.

Examples: *100 push-ups, Drink 8 glasses of water, Write 500 words*

- User defines:
  - `Unit Label` (reps, glasses, words, km, minutes…)
  - `Daily Target` (the value that reaches Level 4 / "Full")
  - `Overachieve Target` (the value that reaches Level 5 / "Overachieved")
  - `Intensity Thresholds` for Levels 1, 2, 3 (user sets the breakpoints)
- Logging: Tap the + button on the card to log one increment; long-press opens a numeric input for bulk entry
- Graph: Full 6-level intensity activated

---

**Type C — Timed Habit (Duration-Based)**  
A habit tracked by time spent.

Examples: *Study session, Practice guitar, Deep work*

- User defines:
  - `Daily Target Duration` (in minutes)
  - `Intensity Thresholds` for each level
- Logging: Tap to start a built-in timer; timer runs in background; tap again to stop and auto-log
- The timer session count is preserved and displayed on the card
- Graph: 6-level intensity based on total daily duration

### 3.2 Habit Card Anatomy

Each habit card on the dashboard displays:

```
┌────────────────────────────────────────────────────┐
│  ● [COLOR DOT]  Habit Name                  14d 🔥 │
│  ─────────────────────────────────────────────────  │
│  [Mini 7-day Sparkline Graph]         [+] Log      │
│  Progress: ████████░░  80/100 reps today           │
└────────────────────────────────────────────────────┘
```

- **Color dot:** User-defined habit color
- **Streak badge:** Current streak (days)
- **Mini sparkline:** Last 7 days of intensity — always visible
- **Log button:** Type-appropriate action (check / + / timer)
- **Progress bar:** Only for Type B and Type C habits

### 3.3 Habit Creation Flow

The habit creation sheet opens as a **bottom sheet** with `presentationDetents([.fraction(0.6), .large])`.

**Steps inside the creation flow:**

1. **Name & Icon** — Habit name (text field), optional emoji/SF Symbol picker
2. **Type Selection** — Binary / Counted / Timed (animated toggle selector)
3. **Graph Color** — Color picker from user's custom palette (see Section 9)
4. **Target Definition** — Appears conditionally based on type selected
5. **Schedule** — Daily / Custom days of week / Specific interval (every N days)
6. **Reminder** — Toggle to enable a local notification + time picker
7. **Review & Create** — Summary card with live graph preview showing what the card will look like

---

## 4. Daily Tasks Module

### 4.1 Concept

Daily Tasks are **distinct from habits**. A habit is a recurring behavioral commitment. A task is a **specific, finite action** the user commits to completing today.

The Daily Tasks module is not a to-do list — it is a **daily commitment board.** Each morning (or whenever the user chooses), they define what they want to accomplish that day. At the end of the day, those tasks are locked and their completion states flow into the **Task Contribution Graph.**

### 4.2 The Task Contribution Graph

Unlike the per-habit graph, the Task Graph represents a single unified view of how well the user executes on their daily intentions.

**How the cell value is calculated each day:**

```
Task Completion Rate = (Tasks Completed / Tasks Set) × 100%
```

| Completion Rate | Graph Intensity |
|-----------------|-----------------|
| 0% | Level 0 — Empty |
| 1–24% | Level 1 — Minimal |
| 25–49% | Level 2 — Low |
| 50–74% | Level 3 — Medium |
| 75–99% | Level 4 — Full |
| 100% | Level 5 — Perfect Day |

A **Perfect Day** (all tasks completed) applies a special visual treatment to the cell — a subtle inner glow or distinctive border using the accent color.

### 4.3 Task Card Anatomy

```
┌────────────────────────────────────────────────────┐
│  ☐  Task description text goes here                │
│     ⏰ Optional time anchor    [Priority badge]     │
└────────────────────────────────────────────────────┘
```

- **Checkbox:** Tap to toggle complete/incomplete
- **Time anchor:** Optional — user can attach a time of day to a task
- **Priority:** Optional badge — Low / Medium / High

### 4.4 Task Behaviors

- Tasks are **non-recurring by default.** Each day starts with an empty board.
- **Template Tasks:** User can mark tasks as "template" — they appear as greyed-out suggestions every morning, one tap to activate them for today.
- **Rollover:** If a task is not completed, a gentle prompt asks the user the next morning if they want to roll it over.
- **Archive:** All past tasks are archived and feed the Task Contribution Graph retroactively.

---

## 5. Statistics & Analytics Module

### 5.1 Overview Page — "Momentum Dashboard"

This is the app's primary analytics screen, accessible via the stats tab. It contains:

**Macro Streak Score:**  
A single "Momentum Score" that aggregates the user's overall consistency across all active habits. Displayed as a large number at the top of the screen with its own mini contribution grid showing the last 30 days.

Formula:
```
Momentum Score = Weighted average of (habit streak × habit frequency weight)
```

**Seriousness Index:**  
A proprietary metric displayed as a percentage that measures the ratio of days with at least one habit completion in the last 90 days. Displayed as a circular gauge.

```
Seriousness Index = (Active Days in last 90 days / 90) × 100%
```

---

### 5.2 Per-Habit Statistics Card

Each habit has a dedicated statistics view accessible by tapping its name. It includes:

| Metric | Description |
|--------|-------------|
| **Current Streak** | Consecutive days with any activity |
| **Best Streak** | All-time personal record |
| **Total Active Days** | Lifetime count |
| **Completion Rate (30d)** | % of days in last 30 with completion |
| **Completion Rate (All Time)** | % since creation |
| **Average Daily Count** | For Type B/C habits |
| **Best Day Ever** | Highest count/duration in a single day |
| **Total Lifetime Volume** | Sum of all logged units |
| **Trend Arrow** | ↑ ↓ → based on last 14-day vs prior 14-day comparison |

The full **365-day Sequence Graph** is displayed at the top of this view, with year navigation.

---

### 5.3 Yearly Review

At the end of each year (or on demand), a shareable "Year in Sequence" summary is generated — a beautiful card showing all habit graphs side by side, total active days, best streak, and top habit. **Exportable as an image.**

---

## 6. Notification System

### 6.1 Notification Types

**Type 1 — Habit Reminder**  
Triggered at a user-defined time for each habit individually. 

- Notification body: *"Time to [habit name]. You're on a [N]-day streak — don't break it."*
- Action buttons (iOS rich notification): `Log Now` / `Snooze 30 min`
- `Log Now` triggers a background task that marks the habit as completed without opening the app

**Type 2 — Streak at Risk**  
Triggered automatically at **21:00 local time** if a habit has not been logged that day and the user has an active streak ≥ 3 days.

- Notification body: *"Your [N]-day [habit name] streak ends tonight. 3 hours left."*
- This notification type respects a user-configurable "Do Not Disturb" window.

**Type 3 — Daily Task Reminder**  
A morning notification (user-configured time, default 08:00) summarizing the day's task board.

- Notification body: *"Good morning. You have [N] tasks planned for today."*
- If the task board is empty: *"No tasks set yet. What will you accomplish today?"*

**Type 4 — Milestone Celebration**  
Triggered when the user hits a streak milestone: 7, 14, 30, 60, 90, 180, 365 days.

- Notification body: *"[N]-day streak on [habit name]. This is what consistency looks like."*
- Tapping opens the habit's statistics view with a celebratory animation.

### 6.2 Background Execution

All notifications are scheduled via `UNUserNotificationCenter` and fire locally — **no server required.** The app requests `BGAppRefreshTask` permission to:

- Re-schedule the next 64 notifications dynamically (iOS limit)
- Refresh streak counts at midnight
- Process any pending background log actions from rich notification interactions

### 6.3 Notification Permission Flow

Notification permission is requested **during onboarding** (Step 4), not at app launch. The user sees a custom pre-permission screen explaining *why* notifications matter for their streaks before the system prompt appears.

---

## 7. Onboarding & First Launch Flow

### 7.1 Splash Screen

- **Duration:** 1.2 seconds
- **Content:** App logo (user-supplied) centered on `SequenceColor.background`, animated with a subtle scale-up spring reveal (`.sequenceStructural`)
- **Transition:** Dissolves into onboarding or main app (if already onboarded)

### 7.2 Onboarding Flow (5 Screens)

The onboarding is a full-screen interactive walkthrough using `TabView` with `.tabViewStyle(.page)` and custom page indicators.

---

**Screen 1 — The Concept**

Visual: An animated Sequence Graph slowly populating with color, square by square, left to right.  
Headline: `"Every day is a square."`  
Subtext: `"Sequence tracks your habits the way GitHub tracks your code — as a living visual record of consistency."`

---

**Screen 2 — How the Graph Works**

Visual: An interactive demo — the user can tap 5 cells on a mini graph and watch the color intensities change.  
Headline: `"The more you do, the deeper the color."`  
Subtext: `"Each habit has its own graph. Tap a square to see your history. Build something worth looking at."`

---

**Screen 3 — Create Your First Habit**

Visual: The habit creation card appearing with a spring animation.  
Headline: `"What do you want to build?"`  
Action: A live mini creation form — user types a habit name and picks a color. This is their real first habit. It gets created in the system immediately.

---

**Screen 4 — Notifications**

Visual: A phone notification appearing on screen.  
Headline: `"Let Sequence remind you."`  
Subtext: `"Streak-at-risk alerts keep your chain alive. You'll only hear from us when it matters."`  
Action: **"Enable Reminders" button** → triggers `UNUserNotificationCenter.requestAuthorization`  
Secondary: `"Maybe later"` link (skippable — re-prompted after first streak is established)

---

**Screen 5 — You're Ready**

Visual: A full beautiful empty graph, all grey squares waiting to be filled.  
Headline: `"Your first square is waiting."`  
Subtext: `"Today is Day 1. Make it green."`  
CTA: Full-width `"Start Sequence"` button → transitions to main app with a `matchedGeometryEffect` from the CTA into the first habit card.

### 7.3 Interactive Coach Marks (First Session)

On the first session after onboarding, **coach marks** guide the user through the main UI:

1. **Coach Mark 1:** Arrow pointing to the habit card log button → *"Tap here to log your habit"*
2. **Coach Mark 2:** Arrow pointing to the mini sparkline → *"This is your last 7 days"*
3. **Coach Mark 3:** Arrow pointing to the stats tab → *"Track your momentum here"*
4. **Coach Mark 4:** Arrow pointing to the + FAB → *"Add more habits here"*

Each coach mark dismisses with a tap. All 4 are shown in sequence, one at a time. They never appear again after dismissal. State stored in `UserDefaults`.

---

## 8. App Screen Architecture

### 8.1 Navigation Structure

```
App
├── Splash Screen
├── Onboarding (first launch only)
│   ├── Screen 1 — Concept
│   ├── Screen 2 — Graph Demo
│   ├── Screen 3 — First Habit Creation
│   ├── Screen 4 — Notifications
│   └── Screen 5 — Ready
│
└── Main App (Tab Bar — 4 tabs)
    │
    ├── 📊 Today  [Tab 1 — Default]
    │   ├── Dashboard Header (streak summary)
    │   ├── Horizontal 7-day Continuity Strip
    │   ├── Habit Cards List (scrollable)
    │   └── FAB (+) → Habit Creation Sheet
    │
    ├── 📅 Tasks  [Tab 2]
    │   ├── Today's Task Board
    │   ├── Task Completion Progress Bar
    │   ├── Task Contribution Graph (full year)
    │   └── FAB (+) → Add Task
    │
    ├── 📈 Stats  [Tab 3]
    │   ├── Momentum Dashboard
    │   ├── Seriousness Index Gauge
    │   ├── Per-Habit Stats Cards (scrollable)
    │   └── Yearly Review Export Card
    │
    └── ⚙️ Settings  [Tab 4]
        ├── Appearance (Dark / Light / System)
        ├── Color Palette Management
        ├── Notification Preferences
        ├── Default Reminder Time
        ├── Week Start Day (Monday / Sunday)
        ├── Graph Direction (Oldest → Newest or reversed)
        ├── Data Export (JSON)
        └── About / Version
```

### 8.2 Modal / Sheet Flows

All creation and detail views use **bottom sheets** or **matched geometry transitions** — never traditional navigation stack pushes for content within the main experience.

| Action | Presentation Style |
|--------|--------------------|
| Create new habit | Bottom sheet (`.fraction(0.6)` → `.large`) |
| Habit detail / full graph | `matchedGeometryEffect` from card |
| Add task | Bottom sheet (`.fraction(0.4)`) |
| Notification settings | Push (Settings context only) |
| Yearly Review | Full-screen cover with share sheet |
| Cell tap tooltip | Popover anchored to tapped cell |

---

## 9. Customization Engine

### 9.1 Philosophy

**The user owns every visual decision.** Sequence provides structure; the user provides personality. No two instances of the app should look identical.

### 9.2 Per-Habit Customization

| Property | Options |
|----------|---------|
| **Name** | Free text, max 40 chars |
| **Icon** | SF Symbol picker (600+ symbols) OR emoji |
| **Graph Color** | Selected from user's palette (see 9.3) |
| **Habit Type** | Binary / Counted / Timed |
| **Schedule** | Daily / Custom weekdays / Every N days |
| **Intensity Thresholds** | User-defined breakpoints for Levels 1–5 |
| **Unit Label** | Custom text (reps, glasses, pages, km…) |
| **Reminder** | Per-habit time + toggle |
| **Archived** | Soft-hide without deleting |

### 9.3 Color Palette System

The user manages a **personal color palette** in Settings → Color Palette.

**Default Palette (6 colors pre-loaded):**
- Sequence Teal: `#48A69E` (default)
- Electric Blue: `#4A90E2`
- Warm Amber: `#E6A817`
- Coral Red: `#E05C5C`
- Soft Purple: `#8E6FD8`
- Forest Green: `#3D8B37`

**Adding Custom Colors:**
- User taps `+` → Opens a **full HSB color picker** with hex input support
- Selected color is automatically generated into a **6-level intensity scale** using HSB lightness/saturation mapping:

```swift
// Intensity generation logic
func generateIntensityScale(base: Color) -> [Color] {
    // Level 0: surfaceSecondary (empty state)
    // Level 1–5: HSB saturation decreases from full base toward white
    // Level 5: HSB value decreased slightly for "overachieved" darkness
}
```

**Removing Colors:**
- Colors in use by active habits cannot be deleted (user is shown which habits use it)
- Archived habits' colors can be deleted with a confirmation

### 9.4 App-Wide Customization

| Setting | Options |
|---------|---------|
| **Appearance** | Light / Dark / System default |
| **Week Start** | Monday / Sunday |
| **Graph Direction** | Recent-right (default) / Recent-left |
| **Streak Threshold** | Minimum level to count as a "streak day" (default: Level 1) |
| **Coach Marks** | Reset (for re-watching the tutorial) |

---

## 10. Data Architecture

### 10.1 Persistence Layer

The app uses **SwiftData** (iOS 17+) for all persistent storage. No cloud sync in v1.0 — all data is local and private.

### 10.2 Core Data Models

```swift
@Model
final class Habit {
    var id: UUID
    var name: String
    var iconIdentifier: String          // SF Symbol name or emoji
    var colorHex: String                // Base color hex
    var type: HabitType                 // .binary / .counted / .timed
    var unit: String?                   // For counted types
    var dailyTarget: Double             // Target for Level 4
    var overachieveTarget: Double       // Target for Level 5
    var thresholds: [Double]            // [L1, L2, L3] breakpoints
    var schedule: HabitSchedule         // Daily / custom
    var reminderTime: Date?
    var isArchived: Bool
    var createdAt: Date
    var logs: [HabitLog]                // Relationship
}

@Model
final class HabitLog {
    var id: UUID
    var habitId: UUID
    var date: Date                      // Normalized to midnight local
    var value: Double                   // Count / duration / 1.0 for binary
    var loggedAt: Date                  // Exact timestamp
}

@Model
final class DailyTask {
    var id: UUID
    var title: String
    var date: Date                      // The day this task belongs to
    var isCompleted: Bool
    var completedAt: Date?
    var priority: TaskPriority          // .low / .medium / .high
    var timeAnchor: Date?               // Optional time of day
    var isTemplate: Bool                // Appears as suggestion each morning
}
```

### 10.3 Computed Properties

No raw data is ever displayed to the UI directly. A `SequenceRepository` layer (as defined in `product_design.md`) handles all fetching, aggregation, and business logic.

Key computed functions:

```swift
// Returns the intensity level (0–5) for a habit on a given date
func intensityLevel(for habit: Habit, on date: Date) -> Int

// Returns the current streak count for a habit
func currentStreak(for habit: Habit) -> Int

// Returns the Seriousness Index (0–100)
func seriousnessIndex(lookback days: Int) -> Double

// Returns the Momentum Score
func momentumScore() -> Double

// Returns all cells for the contribution graph (365 days)
func graphCells(for habit: Habit, year: Int) -> [GraphCell]
```

### 10.4 Data Export

Users can export all their data as a structured JSON file from Settings. Format:

```json
{
  "exportedAt": "2025-01-15T10:30:00Z",
  "habits": [
    {
      "id": "...",
      "name": "Push-ups",
      "type": "counted",
      "logs": [
        { "date": "2025-01-14", "value": 87 },
        { "date": "2025-01-13", "value": 100 }
      ]
    }
  ],
  "tasks": [...]
}
```

---

## 11. Animation & Interaction Philosophy

All animation decisions must conform to `product_design.md`. Key interaction moments specific to Sequence:

### 11.1 Graph Cell Population

When the Today screen loads or refreshes, the contribution graph cells animate in with a **staggered reveal**:
- Cells appear column by column, left to right
- Each column uses `.sequenceFluid` with a `0.02s` delay multiplier per column index
- Color fill uses opacity from 0 → 1 combined with scale from 0.6 → 1.0

### 11.2 Habit Logging Feedback

When the user logs a habit:
1. Haptic feedback fires (`.medium` impact)
2. The log button animates with `.sequenceMicro` scale pulse
3. The mini sparkline updates in real-time — the rightmost cell transitions from its old color to its new intensity
4. If a streak milestone is hit, a subtle particle burst animation fires above the card (using Canvas API)
5. If this is the first log of the day, the "Today" header streak counter increments with a spring bounce

### 11.3 Streak Break (Missed Day)

When the user opens the app the day after a missed habit:
- The habit card shows a **subtle red-tinted left border** (1pt, `#E05C5C` at 40% opacity)
- The streak counter shows `0d` with the previous streak in parentheses: `0d (was 23d)`
- No aggressive modal or guilt-trip UI — the visual context is enough

### 11.4 Perfect Day Celebration

When the Task graph records a 100% completion day:
- The corresponding cell in the Task Contribution Graph gets a **brief pulse animation** with an accent ring
- A non-intrusive banner slides in from the top (not a system alert): *"Perfect day. All tasks complete."*
- Auto-dismisses after 3 seconds

---

## 12. Technical Implementation Checklist

### Pre-Development
- [ ] `product_design.md` reviewed and understood in full
- [ ] SwiftData schema finalized and reviewed
- [ ] `SequenceColor` token system implemented before any UI work
- [ ] Custom `Animation` extensions implemented before any interactive UI work
- [ ] Navigation architecture scaffolded (TabView + sheet coordination)

### Core Features
- [ ] Contribution graph rendering engine (cell grid, color mapping, zoom levels)
- [ ] Habit CRUD (Create, Read, Update, Archive)
- [ ] Binary habit logging
- [ ] Counted habit logging (+ button, bulk input)
- [ ] Timed habit logging (timer, background continuation)
- [ ] Streak calculation engine
- [ ] Intensity level calculation engine
- [ ] Task board CRUD
- [ ] Task contribution graph
- [ ] Statistics computation layer (all metrics)

### UI Screens
- [ ] Splash screen
- [ ] Onboarding (5 screens)
- [ ] Coach marks (first session)
- [ ] Today dashboard
- [ ] Habit detail + full graph view
- [ ] Habit creation sheet
- [ ] Task board screen
- [ ] Statistics / Momentum dashboard
- [ ] Per-habit statistics detail
- [ ] Settings screen
- [ ] Color palette manager
- [ ] Data export flow

### Notifications & Background
- [ ] `UNUserNotificationCenter` permission flow
- [ ] Habit reminder scheduling
- [ ] Streak-at-risk detection and scheduling
- [ ] Morning task summary notification
- [ ] Milestone celebration notifications
- [ ] `BGAppRefreshTask` registration and handler
- [ ] Background notification action (`Log Now`) handler

### Customization
- [ ] Per-habit color assignment
- [ ] Custom color creation with HSB picker
- [ ] Automatic intensity scale generation from base color
- [ ] Dark/Light/System mode toggle
- [ ] Week start configuration
- [ ] Graph direction configuration

### Quality & Polish
- [ ] All animations use custom spring constants (no `.easeInOut` anywhere)
- [ ] Dark mode tested on all screens
- [ ] All views < 120 lines (modular architecture)
- [ ] Lazy collections in all scroll views
- [ ] Haptic feedback on all primary interactions
- [ ] Empty states on all list screens
- [ ] Skeleton loading on stats screen
- [ ] Data export functional
- [ ] Yearly review image generation and share sheet

---

**END OF CONCEPT DOCUMENT**

This document is the product north star for Sequence. Every screen, interaction, and data decision described here must be implemented in full. Reference `product_design.md` for all visual constants, color tokens, animation curves, and code architecture rules.

Assets (logo, icons, brand assets) will be provided separately and placed in the Xcode asset catalog at project setup.
