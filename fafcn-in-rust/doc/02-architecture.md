# Architecture

## System Overview

Pure client-side application with no backend dependencies.

```
┌─────────────────────────────────────────────┐
│           BROWSER                           │
│  ┌───────────────────────────────────────┐  │
│  │        DIOXUS APP (WASM)              │  │
│  │                                       │  │
│  │  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │    Router    │  │    State     │  │  │
│  │  │   (Pages)    │  │   (Signals)  │  │  │
│  │  └──────┬───────┘  └──────┬───────┘  │  │
│  │         │                 │          │  │
│  │         └────────┬────────┘          │  │
│  │                  │                   │  │
│  │         ┌────────▼────────┐          │  │
│  │         │   Components    │          │  │
│  │         │  - UnitGrid     │          │  │
│  │         │  - BuildQueue   │          │  │
│  │         │  - EcoChart     │          │  │
│  │         └────────┬────────┘          │  │
│  │                  │                   │  │
│  │  ┌───────────────┴───────────────┐   │  │
│  │  │      Data Layer               │   │  │
│  │  │  - MockUnitData (embedded)    │   │  │
│  │  │  - EcoSimulator (WASM)        │   │  │
│  │  │  - LocalStorage (persistent)  │   │  │
│  │  └───────────────────────────────┘   │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Crate Structure

### fafcn-core

**Purpose**: Domain logic, completely pure Rust.

**Contains**:
- `models/unit.rs` - Unit data structures
- `models/user.rs` - User (minimal, for future auth)
- `eco/state.rs` - EcoState, BuildItem
- `eco/simulator.rs` - EcoSimulator

**No dependencies on**: async, web, I/O

### fafcn-web

**Purpose**: Dioxus frontend application.

**Contains**:
- `app.rs` - Root component, router
- `state/` - Global state management
- `components/` - Reusable UI components
- `pages/` - Route-level components
- `hooks/` - Custom hooks
- `data/` - Mock data

## Data Flow

### Simulation Flow

```
User Input → EcoState Signal → Debounced → Simulation
                                              │
                                              ▼
Timeline ← SimulationResult Signal ← EcoSimulator
   │
   ▼
Chart Re-render (Canvas)
```

1. User changes mass income input
2. Dioxus signal updates (reactive)
3. Debounced simulation trigger (300ms)
4. EcoSimulator runs in WASM
5. Result stored in signal
6. Chart component re-renders

### Drag-Drop Flow

```
Drag Start → Set dragged_index
    │
Drag Over → Set drag_over_index
    │
Drop → Reorder queue array
    │
Save to LocalStorage
```

## State Management

### Global State

```rust
pub struct AppState {
    // Eco simulation
    pub eco_state: Signal<EcoState>,
    pub build_queue: Signal<Vec<BuildItem>>,
    pub simulation_result: Signal<Option<SimulationResult>>,
    
    // UI state
    pub selected_faction: Signal<Option<Faction>>,
    pub active_filters: Signal<FilterState>,
    
    // Persistence
    pub saved_simulations: Signal<Vec<SavedSimulation>>,
}
```

### Local State

```rust
#[component]
fn UnitCard(unit: Unit) -> Element {
    let is_hovered = use_signal(|| false);  // Component-only
    
    rsx! {
        div {
            onmouseenter: move |_| is_hovered.set(true),
            onmouseleave: move |_| is_hovered.set(false),
            // ...
        }
    }
}
```

### Persistence

```rust
// Auto-save to LocalStorage
use_effect({
    let state = state.clone();
    move || {
        let data = serialize_state(&state);
        save_to_local_storage("fafcn_state", &data);
    }
});
```

## Component Hierarchy

```
App
├── Router
│   ├── Home
│   │   └── HeroSection
│   │
│   ├── EcoGuides
│   │   ├── FactionTabs
│   │   ├── FilterBar
│   │   ├── UnitGrid
│   │   │   └── UnitCard (xN)
│   │   └── UnitDetail (modal)
│   │
│   └── EcoPrediction
│       ├── EcoInputs
│       │   ├── ResourceInput (mass)
│       │   ├── ResourceInput (energy)
│       │   └── EngineerInput
│       ├── UnitSelector
│       │   └── UnitGrid
│       ├── BuildQueue (drag-drop)
│       │   └── QueueItem (xN)
│       ├── RunButton
│       └── ResultsPanel
│           ├── Timeline
│           └── EcoChart (canvas)
```

## File Organization

```
crates/fafcn-web/src/
├── main.rs              # Entry
├── app.rs               # App + Router
├── lib.rs               # Exports (optional)
│
├── state/
│   ├── mod.rs           # AppState struct
│   ├── eco.rs           # Eco simulation state
│   ├── filters.rs       # Filter state
│   └── persistence.rs   # LocalStorage helpers
│
├── components/
│   ├── mod.rs           # Component exports
│   ├── common/          # Shared components
│   │   ├── button.rs
│   │   ├── input.rs
│   │   └── card.rs
│   ├── unit/            # Unit-related
│   │   ├── grid.rs
│   │   ├── card.rs
│   │   └── detail.rs
│   └── eco/             # Eco-related
│       ├── inputs.rs
│       ├── build_queue.rs
│       ├── timeline.rs
│       └── chart.rs
│
├── pages/
│   ├── mod.rs
│   ├── home.rs
│   ├── eco_guides.rs
│   └── eco_prediction.rs
│
├── hooks/
│   ├── mod.rs
│   ├── use_drag_drop.rs
│   ├── use_debounce.rs
│   ├── use_local_storage.rs
│   └── use_simulation.rs
│
└── data/
    ├── mod.rs           # Data exports
    └── units.rs         # Hardcoded unit data
```

## Key Design Decisions

### 1. No Backend Required

All data is either:
- Hardcoded in the binary (units)
- Computed in WASM (simulations)
- Stored in LocalStorage (user state)

### 2. Fafcn-core is Sync

No async, no web-sys. Pure logic that can be tested without a browser.

### 3. State is Reactive

Dioxus signals provide fine-grained reactivity.

### 4. Canvas for Charts

HTML5 Canvas gives us full control over rendering and interactions (zoom, pan, hover).

### 5. Mock Data is Real Data

Export your existing Elixir database to JSON, embed it in the binary.

## Next

[State Management](./03-state-management.md)
