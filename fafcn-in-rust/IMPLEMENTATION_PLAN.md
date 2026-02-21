# FAF CN - Final Implementation Plan

**Strategy: Pure Frontend Demo (No Backend Required)**

## Overview

Build a Dioxus-based SPA that demonstrates all eco features without a backend:
- 400+ FAF units browsable
- Real eco simulation (Rust → WASM)
- Drag-drop build queue
- Interactive charts
- Offline support
- LocalStorage persistence

**Timeline: 3-4 weeks**

## Phase Breakdown

### Week 1: Foundation (fafcn-core)

**Goal**: Domain models and eco simulation engine

**Tasks**:
1. Create workspace structure
2. Implement Unit, Faction, EcoState models
3. Build EcoSimulator with tick-based simulation
4. Export unit data from Elixir DB to JSON
5. Write comprehensive tests

**Deliverables**:
- `crates/fafcn-core/` with all domain logic
- Unit tests passing
- Mock unit data ready

**Key Code**:
```rust
// EcoSimulator::simulate() - pure function
pub fn simulate(config: &SimulationConfig) -> SimulationResult {
    // Run tick-based simulation
    // Return timeline + resource history
}
```

### Week 2: Web App (fafcn-web)

**Goal**: Dioxus app with routing and basic UI

**Tasks**:
1. Set up Dioxus project
2. Configure router (Home, EcoGuides, EcoPrediction)
3. Implement global state (AppState with signals)
4. Build UnitGrid with filtering
5. Create EcoInputs form

**Deliverables**:
- `crates/fafcn-web/` with basic UI
- Unit browsing works
- State persistence in LocalStorage

**Key Components**:
- `UnitCard`, `UnitGrid`
- `EcoInputs`
- `AppState` with signals

### Week 3: Complex Features

**Goal**: Drag-drop, charts, simulation

**Tasks**:
1. Implement drag-drop BuildQueue
2. Create Canvas-based EcoChart (zoom/pan)
3. Wire up EcoSimulator
4. Add timeline visualization
5. Polish UI with Tailwind

**Deliverables**:
- Full eco prediction workflow
- Interactive charts
- Smooth animations

**Key Components**:
- `BuildQueue` with drag-drop hook
- `EcoChart` with canvas
- `Timeline` component

### Week 4: Polish & Deploy

**Goal**: Production-ready demo

**Tasks**:
1. Optimize WASM bundle size
2. Add loading states
3. Test on mobile
4. Deploy to GitHub Pages/Netlify
5. Write announcement post

**Deliverables**:
- Live demo URL
- Shareable build
- Documentation complete

## File Structure

```
fafcn-in-rust/
├── Cargo.toml                      # Workspace
├── crates/
│   ├── fafcn-core/                 # Domain logic
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── models/
│   │       │   ├── mod.rs
│   │       │   ├── unit.rs         # Unit, Faction
│   │       │   └── user.rs         # User (minimal)
│   │       └── eco/
│   │           ├── mod.rs
│   │           ├── state.rs        # EcoState
│   │           ├── build_item.rs   # BuildItem
│   │           └── simulator.rs    # EcoSimulator
│   │
│   └── fafcn-web/                  # Dioxus frontend
│       ├── Cargo.toml
│       ├── Dioxus.toml
│       ├── src/
│       │   ├── main.rs             # Entry
│       │   ├── app.rs              # Router
│       │   ├── state/
│       │   │   ├── mod.rs          # AppState
│       │   │   ├── eco.rs          # Eco state
│       │   │   └── persistence.rs  # LocalStorage
│       │   ├── components/
│       │   │   ├── mod.rs
│       │   │   ├── common/         # Button, Card
│       │   │   ├── unit/           # UnitCard, UnitGrid
│       │   │   └── eco/            # EcoInputs, BuildQueue, EcoChart
│       │   ├── pages/
│       │   │   ├── mod.rs
│       │   │   ├── home.rs
│       │   │   ├── eco_guides.rs
│       │   │   └── eco_prediction.rs
│       │   ├── hooks/
│       │   │   ├── mod.rs
│       │   │   ├── use_drag_drop.rs
│       │   │   ├── use_debounce.rs
│       │   │   └── use_local_storage.rs
│       │   └── data/
│       │       ├── mod.rs
│       │       └── units.rs        # Hardcoded units
│       │
│       └── assets/
│           ├── tailwind.css
│           └── images/             # Unit icons
│
└── doc/                            # Documentation
    ├── 01-quick-start.md
    ├── 02-architecture.md
    ├── 03-state-management.md
    ├── 04-components.md
    └── 05-deployment.md
```

## Key Technologies

| Layer | Tech | Purpose |
|-------|------|---------|
| Core | Serde + Chrono | Models + serialization |
| Frontend | Dioxus 0.5 | UI framework |
| State | Dioxus Signals | Reactive state |
| Styling | Tailwind CSS | Styling |
| Canvas | web-sys Canvas | Charts |
| Storage | LocalStorage | Persistence |

## Commands

```bash
# Run dev server
cd crates/fafcn-web && dx serve --hot-reload

# Test core
cargo test -p fafcn-core

# Build production
dx build --release

# Deploy to GitHub Pages
# (copy dist/ to gh-pages branch)
```

## Data Flow

```
User clicks unit
    ↓
Add to build_queue signal
    ↓
Trigger debounced simulation
    ↓
EcoSimulator::simulate() (WASM)
    ↓
Update simulation_result signal
    ↓
Re-render chart + timeline
    ↓
Auto-save to LocalStorage
```

## Bundle Size Target

| Asset | Target |
|-------|--------|
| WASM | < 300KB gzipped |
| Total | < 500KB |
| First Load | < 2s on 3G |

## Success Criteria

- [ ] All 400+ units browsable
- [ ] Eco simulation accurate
- [ ] Drag-drop works smoothly
- [ ] Charts interactive (zoom/pan)
- [ ] Works offline
- [ ] Mobile responsive
- [ ] Deployed and shareable

## Ready to Start!

Begin with [doc/01-quick-start.md](./doc/01-quick-start.md)

Let's build this! 🚀
