# State Management

Dioxus uses Signals for reactive state management.

## Signal Basics

```rust
use dioxus::prelude::*;

// Create a signal
let count = use_signal(|| 0);

// Read value
println!("{}", count());  // 0

// Update value
count.set(5);

// Modify based on previous
count += 1;  // count.set(count() + 1);

// Reactive - components re-render when signal changes
```

## Global State Pattern

### 1. Define State Struct

```rust
// src/state/mod.rs

use dioxus::prelude::*;
use fafcn_core::{
    eco::{EcoState, BuildItem, SimulationResult},
    models::{Faction, Unit},
};

#[derive(Clone)]
pub struct AppState {
    // Eco simulation
    pub eco: Signal<EcoState>,
    pub build_queue: Signal<Vec<BuildItem>>,
    pub simulation_result: Signal<Option<SimulationResult>>,
    pub is_simulating: Signal<bool>,
    
    // UI
    pub selected_faction: Signal<Option<Faction>>,
    pub selected_unit: Signal<Option<Unit>>,
    pub active_filters: Signal<FilterState>,
    
    // History
    pub saved_simulations: Signal<Vec<SavedSimulation>>,
}

#[derive(Clone, Default)]
pub struct FilterState {
    pub faction: Option<Faction>,
    pub tech_level: Option<String>,
    pub category: Option<String>,
    pub search: String,
}

#[derive(Clone)]
pub struct SavedSimulation {
    pub id: String,
    pub name: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub config: SimulationConfig,
    pub result: SimulationResult,
}
```

### 2. Create Provider Component

```rust
// src/state/mod.rs

#[component]
pub fn AppStateProvider(children: Element) -> Element {
    let state = AppState {
        eco: use_signal(|| EcoState::with_initial_eco(
            10.0, 100.0, 650.0, 2500.0, 10.0
        )),
        build_queue: use_signal(Vec::new),
        simulation_result: use_signal(|| None),
        is_simulating: use_signal(|| false),
        
        selected_faction: use_signal(|| None),
        selected_unit: use_signal(|| None),
        active_filters: use_signal(FilterState::default),
        
        saved_simulations: use_signal(Vec::new),
    };
    
    // Load from LocalStorage on mount
    use_effect({
        let state = state.clone();
        move || {
            if let Some(saved) = load_from_storage() {
                state.eco.set(saved.eco);
                state.build_queue.set(saved.build_queue);
                state.saved_simulations.set(saved.saved_simulations);
            }
        }
    });
    
    // Auto-save on changes
    use_effect({
        let state = state.clone();
        move || {
            let data = PersistedData {
                eco: state.eco(),
                build_queue: state.build_queue.read().clone(),
                saved_simulations: state.saved_simulations.read().clone(),
            };
            save_to_storage(&data);
        }
    });
    
    use_context_provider(|| state);
    
    rsx! { {children} }
}

// Hook to access state
pub fn use_app_state() -> AppState {
    use_context::<AppState>().expect("AppState not found")
}
```

### 3. Use in Components

```rust
// src/pages/eco_prediction.rs

use crate::state::use_app_state;

#[component]
pub fn EcoPrediction() -> Element {
    let state = use_app_state();
    
    rsx! {
        div {
            h1 { "Eco Prediction" }
            
            // Auto-updates when eco changes
            p { "Mass income: {state.eco().mass_income}" }
            
            // Form that updates state
            input {
                value: "{state.eco().mass_income}",
                oninput: move |e| {
                    let val = e.value().parse::<f64>().unwrap_or(0.0);
                    state.eco.write().mass_income = val;
                }
            }
            
            // Queue length (reactive)
            p { "Queue: {state.build_queue.read().len()} items" }
        }
    }
}
```

## Computed Values

Use `use_memo` for derived state:

```rust
let total_cost = use_memo({
    let queue = state.build_queue.clone();
    move || {
        queue.read().iter().fold((0, 0), |acc, item| {
            (acc.0 + item.total_mass(), acc.1 + item.total_energy())
        })
    }
});

// Use like a signal
rsx! {
    p { "Total: {total_cost().0}M / {total_cost().1}E" }
}
```

## Async Operations

```rust
// src/hooks/use_simulation.rs

use dioxus::prelude::*;
use fafcn_core::eco::{SimulationConfig, EcoSimulator};

pub fn use_simulation(state: &AppState) {
    // Trigger simulation when queue changes
    use_effect({
        let state = state.clone();
        move || {
            // Debounce - wait 300ms after last change
            spawn(async move {
                gloo_timers::future::TimeoutFuture::new(300).await;
                
                if state.build_queue.read().is_empty() {
                    return;
                }
                
                state.is_simulating.set(true);
                
                let config = SimulationConfig {
                    initial_state: state.eco(),
                    build_queue: state.build_queue.read().clone(),
                    max_simulation_time: 3600.0,
                    tick_rate: 0.1,
                };
                
                // Run simulation (sync, in WASM)
                let result = EcoSimulator::simulate(&config);
                
                state.simulation_result.set(Some(result));
                state.is_simulating.set(false);
            });
        }
    });
}
```

## LocalStorage Persistence

```rust
// src/state/persistence.rs

use serde::{Serialize, Deserialize};
use wasm_bindgen::prelude::*;

#[derive(Serialize, Deserialize, Clone)]
pub struct PersistedData {
    pub eco: EcoState,
    pub build_queue: Vec<BuildItem>,
    pub saved_simulations: Vec<SavedSimulation>,
}

const STORAGE_KEY: &str = "fafcn_v1";

pub fn save_to_storage(data: &PersistedData) {
    if let Ok(json) = serde_json::to_string(data) {
        let storage = web_sys::window()
            .and_then(|w| w.local_storage().ok())
            .flatten();
        
        if let Some(s) = storage {
            let _ = s.set_item(STORAGE_KEY, &json);
        }
    }
}

pub fn load_from_storage() -> Option<PersistedData> {
    let storage = web_sys::window()
        .and_then(|w| w.local_storage().ok())
        .flatten()?;
    
    let json = storage.get_item(STORAGE_KEY).ok()??;
    serde_json::from_str(&json).ok()
}

pub fn clear_storage() {
    let storage = web_sys::window()
        .and_then(|w| w.local_storage().ok())
        .flatten();
    
    if let Some(s) = storage {
        let _ = s.remove_item(STORAGE_KEY);
    }
}
```

## State Modification Patterns

### Pattern 1: Direct Modification

```rust
// Simple update
state.eco.write().mass_income = 20.0;
```

### Pattern 2: Replace Entire Value

```rust
// When computing new state
let new_queue = compute_new_queue(&state.build_queue());
state.build_queue.set(new_queue);
```

### Pattern 3: Batch Updates

```rust
// Multiple related changes
{
    let mut eco = state.eco.write();
    eco.mass_income = 20.0;
    eco.energy_income = 200.0;
    eco.build_power = 20.0;
} // Signals notified here
```

## Best Practices

1. **Keep signals granular** - Don't put everything in one big struct
2. **Use memo for expensive computations** - Avoid recomputing on every render
3. **Debounce user input** - Don't run simulation on every keystroke
4. **Batch writes** - Group related updates
5. **Use effects sparingly** - They run on every change

## Next

[Components](./04-components.md)
