use dioxus::prelude::*;
use fafcn_core::{
    eco::{EcoState, BuildItem, SimulationResult, SimulationConfig, EcoSimulator},
    models::{Faction, Unit, TechLevel, UnitCategory},
};
use serde::{Serialize, Deserialize};

#[derive(Clone, Copy)]
pub struct AppState {
    // Eco simulation
    pub eco: Signal<EcoState>,
    pub build_queue: Signal<Vec<BuildItem>>,
    pub simulation_result: Signal<Option<SimulationResult>>,
    pub is_simulating: Signal<bool>,
    
    // UI state
    pub selected_faction: Signal<Option<Faction>>,
    pub selected_unit: Signal<Option<Unit>>,
    pub active_filters: Signal<FilterState>,
}

#[derive(Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct FilterState {
    pub tech_level: Option<TechLevel>,
    pub category: Option<UnitCategory>,
    pub search: String,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            eco: use_signal(|| EcoState::with_initial_eco(
                10.0, 100.0, 650.0, 2500.0, 10.0
            )),
            build_queue: use_signal(Vec::new),
            simulation_result: use_signal(|| None),
            is_simulating: use_signal(|| false),
            
            selected_faction: use_signal(|| None),
            selected_unit: use_signal(|| None),
            active_filters: use_signal(FilterState::default),
        }
    }
}

pub fn add_to_queue(mut state: AppState, unit: Unit, quantity: i32) {
    state.build_queue.write().push(BuildItem::new(unit, quantity));
    state.simulation_result.set(None);
}

pub fn remove_from_queue(mut state: AppState, index: usize) {
    if index < state.build_queue.read().len() {
        state.build_queue.write().remove(index);
        state.simulation_result.set(None);
    }
}

pub fn move_queue_item(mut state: AppState, from: usize, to: usize) {
    let mut queue = state.build_queue.write();
    if from < queue.len() && to < queue.len() {
        let item = queue.remove(from);
        queue.insert(to, item);
    }
    state.simulation_result.set(None);
}

pub fn update_eco(mut state: AppState, new_eco: EcoState) {
    state.eco.set(new_eco);
    state.simulation_result.set(None);
}

pub fn clear_queue(mut state: AppState) {
    state.build_queue.write().clear();
    state.simulation_result.set(None);
}

pub fn run_simulation(mut state: AppState) {
    let eco = (state.eco)();
    let queue = (state.build_queue)();
    
    if queue.is_empty() {
        return;
    }
    
    state.is_simulating.set(true);
    
    // Calculate total build power
    let build_power = calculate_build_power(&eco);
    
    // Create initial state for simulation
    let mut initial_state = eco.clone();
    initial_state.build_power = build_power as f64;
    
    // Create simulation config
    let config = SimulationConfig {
        initial_state,
        build_queue: queue.to_vec(),
        max_simulation_time: 3600.0,
        tick_rate: 0.1,
    };
    
    // Run simulation
    let result = EcoSimulator::simulate(&config);
    state.simulation_result.set(Some(result));
    state.is_simulating.set(false);
}

fn calculate_build_power(eco: &EcoState) -> f64 {
    // Standard build power values for engineers
    let t1_power = eco.t1_engineers as f64 * 5.0;  // T1 engineers: 5 BP each
    let t2_power = eco.t2_engineers as f64 * 10.0; // T2 engineers: 10 BP each
    let t3_power = eco.t3_engineers as f64 * 15.0; // T3 engineers: 15 BP each
    t1_power + t2_power + t3_power
}

#[component]
pub fn AppStateProvider(children: Element) -> Element {
    let state = AppState::new();
    use_context_provider(|| state);
    rsx! { {children} }
}

pub fn use_app_state() -> AppState {
    use_context::<AppState>()
}
