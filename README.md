<div align="center">

# Sequence

**Track your habits the way GitHub tracks code — a living visual record of consistency.**

A contribution-graph habit tracker for iOS. Every day is a square; every streak is a chain you don't want to break.

`SwiftUI` · `SwiftData` · `iOS 17+`

</div>

---

## What it is

Sequence turns your daily habits into a GitHub-style contribution graph. Instead of a checkbox you forget about, each habit becomes a grid of squares that fills in as you show up — the more you do, the deeper the color. The result is an honest, at-a-glance picture of your consistency over weeks and months.

## Features

- **Contribution graph per habit** — a week-aligned, GitHub-style grid with a 5-level intensity scale derived from how much you did that day.
- **Three habit types** — binary (did / didn't), counted (e.g. 50 reps), and timed (e.g. 30 min) with a built-in timer.
- **Streaks that mean something** — current and best streaks with a configurable intensity threshold, plus a gentle "0d (was 5d)" treatment when a chain breaks.
- **Daily tasks** — a lightweight task board with templates, roll-over of unfinished items, and a "Perfect Day" ring when you clear everything.
- **Stats** — momentum score, a seriousness gauge, per-habit breakdowns, and a shareable "Year in Sequence" review.
- **Smart notifications** — habit reminders, streak-at-risk alerts, a morning task summary, milestone celebrations, quiet hours, and rich "Log now / Snooze" actions. Background refresh keeps everything current.
- **Make it yours** — light / dark / system appearance, custom color palettes, week-start and graph-direction preferences, and full JSON data export.
- **Considered onboarding** — an animated splash, a five-screen intro that creates your first habit, and one-time coach marks.

## Design principles

- **Tokens, not magic numbers** — all color, type, spacing, and radius live in a design system (`SequenceColor`, `Typography`, `Spacing`). No raw hex in views.
- **Motion with intent** — three custom spring curves (`.sequenceStructural`, `.sequenceMicro`, `.sequenceFluid`) for interactive change; never `.easeInOut`/`.linear`.
- **Local-first** — all data stays on device via SwiftData. No accounts, no servers.

## Architecture

```
Sequence/
├── App/            App entry, launch router (splash → onboarding → main)
├── DesignSystem/   Color tokens, typography, spacing, springs, shared components
├── Models/         SwiftData @Models — Habit, HabitLog, DailyTask + enums
├── Data/           SequenceRepository + pure engines (Intensity, Streak, Stats,
│                   ColorScale, ContributionGraphBuilder) + stores & exporter
├── Notifications/  NotificationManager + BackgroundTaskManager
└── Features/       Today, Tasks, Stats, Settings, Onboarding
```

The data layer is split into an `@Observable SequenceRepository` (CRUD + persistence) and a set of **pure, stateless engines** that turn logged values into intensity levels, streaks, and statistics — which keeps the rules unit-testable in isolation (52 tests).

## Getting started

**Requirements:** Xcode 26+, [XcodeGen](https://github.com/yonsm/XcodeGen) (`brew install xcodegen`), an iOS 17+ simulator.

The Xcode project is generated from `project.yml` (the source of truth) — `*.xcodeproj` is gitignored.

```bash
make run        # regenerate, build, and launch on the simulator
make test       # run the unit-test suite
make fresh      # clean install (wipes data, re-shows onboarding)
make help       # list all commands
```

Different simulator? `make run SIMULATOR="iPhone 16 Pro"`.

<details>
<summary>Without the Makefile</summary>

```bash
xcodegen generate
xcodebuild -project Sequence.xcodeproj -scheme Sequence \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
</details>

## Tech stack

| | |
|---|---|
| UI | SwiftUI, `@Observable`, `matchedGeometryEffect` |
| Persistence | SwiftData (`@Model`, `ModelContainer`) |
| Notifications | `UNUserNotificationCenter`, `BGAppRefreshTask` |
| Project gen | XcodeGen |
| Min target | iOS 17 |

## License

No license file yet — add one of your choice (MIT is a common default for open-source apps).
