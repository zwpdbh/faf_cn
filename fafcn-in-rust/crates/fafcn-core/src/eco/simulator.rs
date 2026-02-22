use serde::{Deserialize, Serialize};
use crate::eco::{EcoState, BuildItem};

/// Configuration for a simulation run
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationConfig {
    pub initial_state: EcoState,
    pub build_queue: Vec<BuildItem>,
    #[serde(default = "default_max_time")]
    pub max_simulation_time: f64,
    #[serde(default = "default_tick_rate")]
    pub tick_rate: f64,
}

fn default_max_time() -> f64 { 3600.0 }
fn default_tick_rate() -> f64 { 0.1 }

impl Default for SimulationConfig {
    fn default() -> Self {
        Self {
            initial_state: EcoState::default(),
            build_queue: Vec::new(),
            max_simulation_time: default_max_time(),
            tick_rate: default_tick_rate(),
        }
    }
}

/// A single event in the simulation timeline
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TimelineEvent {
    pub time: f64,
    pub event_type: EventType,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum EventType {
    BuildStarted { unit_id: String },
    BuildCompleted { unit_id: String },
    ResourceStall { resource: ResourceType },
    ResourceFull { resource: ResourceType },
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ResourceType {
    Mass,
    Energy,
}

/// Snapshot of resources at a point in time (for charts)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceSnapshot {
    pub time: f64,
    pub mass: f64,
    pub energy: f64,
    pub mass_income: f64,
    pub energy_income: f64,
    pub mass_drain: f64,
    pub energy_drain: f64,
}

/// Result of a simulation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationResult {
    pub success: bool,
    pub completion_time: Option<f64>,
    pub final_state: EcoState,
    pub timeline: Vec<TimelineEvent>,
    pub resource_history: Vec<ResourceSnapshot>,
    pub items_completed: Vec<BuildItem>,
    pub total_stall_time: f64,
}

pub struct EcoSimulator;

impl EcoSimulator {
    pub fn simulate(config: &SimulationConfig) -> SimulationResult {
        let mut state = config.initial_state.clone();
        let mut timeline = Vec::new();
        let mut history = Vec::new();
        let mut completed_items = Vec::new();
        let mut current_time = 0.0;
        let mut total_stall_time = 0.0;
        let dt = config.tick_rate;

        // Record initial state
        history.push(Self::snapshot(&state, current_time, 0.0, 0.0));

        for item in &config.build_queue {
            let result = Self::simulate_item(
                &mut state,
                item,
                current_time,
                &mut timeline,
                &mut history,
                &mut completed_items,
                &mut total_stall_time,
                dt,
                config.max_simulation_time,
            );

            if let Some(end_time) = result {
                current_time = end_time;
            } else {
                // Simulation aborted (timeout)
                return SimulationResult {
                    success: false,
                    completion_time: None,
                    final_state: state,
                    timeline,
                    resource_history: history,
                    items_completed: completed_items,
                    total_stall_time,
                };
            }
        }

        SimulationResult {
            success: true,
            completion_time: Some(current_time),
            final_state: state,
            timeline,
            resource_history: history,
            items_completed: completed_items,
            total_stall_time,
        }
    }

    fn simulate_item(
        state: &mut EcoState,
        item: &BuildItem,
        start_time: f64,
        timeline: &mut Vec<TimelineEvent>,
        history: &mut Vec<ResourceSnapshot>,
        completed: &mut Vec<BuildItem>,
        total_stall_time: &mut f64,
        dt: f64,
        max_time: f64,
    ) -> Option<f64> {
        let mut current_time = start_time;
        let mut item_progress = 0.0;
        let mass_rate = item.mass_drain_per_sec(state.build_power);
        let energy_rate = item.energy_drain_per_sec(state.build_power);

        timeline.push(TimelineEvent {
            time: current_time,
            event_type: EventType::BuildStarted { 
                unit_id: item.unit.unit_id.clone() 
            },
            description: format!(
                "Started building {} ×{}",
                item.unit.name.as_deref().unwrap_or(&item.unit.unit_id),
                item.quantity
            ),
        });

        while item_progress < 1.0 && current_time < max_time {
            let can_afford = state.can_afford(mass_rate, energy_rate, dt);

            if can_afford {
                state.tick(mass_rate, energy_rate, dt);
                item_progress += (state.build_power * dt) / item.base_build_time();
            } else {
                // Stall - still add income, no drain
                state.tick(0.0, 0.0, dt);
                *total_stall_time += dt;

                // Record stall event (debounced - only every 5 seconds)
                if (*total_stall_time * 10.0) as i64 % 50 == 0 {
                    let stalled_res = if state.mass_storage < mass_rate * dt {
                        ResourceType::Mass
                    } else {
                        ResourceType::Energy
                    };
                    
                    // Only add if last event wasn't same stall
                    let should_add = match timeline.last() {
                        Some(TimelineEvent { 
                            event_type: EventType::ResourceStall { resource }, 
                            .. 
                        }) => *resource != stalled_res,
                        _ => true,
                    };
                    
                    if should_add {
                        timeline.push(TimelineEvent {
                            time: current_time,
                            event_type: EventType::ResourceStall { resource: stalled_res },
                            description: format!("{:?} stall", stalled_res),
                        });
                    }
                }
            }

            // Record history every second
            if (current_time * 10.0) as i64 % (10.0 / dt) as i64 == 0 {
                history.push(Self::snapshot(state, current_time, mass_rate, energy_rate));
            }

            current_time += dt;
        }

        if item_progress >= 1.0 {
            timeline.push(TimelineEvent {
                time: current_time,
                event_type: EventType::BuildCompleted { 
                    unit_id: item.unit.unit_id.clone() 
                },
                description: format!(
                    "Completed {} ×{}",
                    item.unit.name.as_deref().unwrap_or(&item.unit.unit_id),
                    item.quantity
                ),
            });
            completed.push(item.clone());
            Some(current_time)
        } else {
            None // Timeout
        }
    }

    fn snapshot(state: &EcoState, time: f64, mass_drain: f64, energy_drain: f64) -> ResourceSnapshot {
        ResourceSnapshot {
            time,
            mass: state.mass_storage,
            energy: state.energy_storage,
            mass_income: state.mass_income,
            energy_income: state.energy_income,
            mass_drain,
            energy_drain,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{Unit, Faction};
    use chrono::Utc;

    fn create_test_unit() -> Unit {
        Unit {
            id: 1,
            unit_id: "UEB0101".to_string(),
            faction: Faction::Uef,
            name: Some("Test Unit".to_string()),
            description: None,
            build_cost_mass: 100,
            build_cost_energy: 1000,
            build_time: 100,
            categories: vec![],
            data: serde_json::json!({}),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    #[test]
    fn test_simple_simulation() {
        let unit = create_test_unit();
        let item = BuildItem::new(unit, 1);

        let config = SimulationConfig {
            initial_state: EcoState::with_initial_eco(
                10.0, 100.0, 1000.0, 10000.0, 10.0
            ),
            build_queue: vec![item],
            max_simulation_time: 3600.0,
            tick_rate: 0.1,
        };

        let result = EcoSimulator::simulate(&config);

        assert!(result.success);
        assert!(result.completion_time.is_some());
        assert_eq!(result.items_completed.len(), 1);
        
        // Build time = 100 / 10 BP = 10 seconds
        assert!((result.completion_time.unwrap() - 10.0).abs() < 1.0);
    }

    #[test]
    fn test_stall_simulation() {
        let unit = create_test_unit();
        let item = BuildItem::new(unit, 1);

        // Low income - will stall
        let config = SimulationConfig {
            initial_state: EcoState::with_initial_eco(
                1.0, 100.0, 50.0, 10000.0, 10.0
            ),
            build_queue: vec![item],
            max_simulation_time: 100.0,
            tick_rate: 0.1,
        };

        let result = EcoSimulator::simulate(&config);

        assert!(result.success);
        assert!(result.total_stall_time > 0.0);
        
        // Check that stall events were recorded
        let stall_events: Vec<_> = result.timeline.iter()
            .filter(|e| matches!(e.event_type, EventType::ResourceStall { .. }))
            .collect();
        assert!(!stall_events.is_empty());
    }

    #[test]
    fn test_timeout() {
        let unit = create_test_unit();
        let item = BuildItem::new(unit, 1000);

        let config = SimulationConfig {
            initial_state: EcoState::with_initial_eco(
                0.1, 1.0, 10.0, 100.0, 1.0
            ),
            build_queue: vec![item],
            max_simulation_time: 10.0,
            tick_rate: 0.1,
        };

        let result = EcoSimulator::simulate(&config);

        assert!(!result.success);
        assert!(result.completion_time.is_none());
    }
}
