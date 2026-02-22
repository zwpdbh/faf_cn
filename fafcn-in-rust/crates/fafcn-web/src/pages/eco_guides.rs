use dioxus::prelude::*;
use fafcn_core::{Faction, Unit};

use crate::{
    state::use_app_state,
    components::{Header, BaseUnitCard, faction_tabs::FactionTabs, unit_grid::UnitGrid, unit::eco_comparison::EcoComparison},
    data::get_all_units,
};

#[component]
pub fn EcoGuides() -> Element {
    let mut state = use_app_state();
    
    let selected_faction = (state.selected_faction)();
    let faction = selected_faction.unwrap_or(Faction::Uef);
    
    let all_units = get_all_units();
    
    // Get base unit for the current faction (T1 engineer)
    // Get the T1 engineer unit ID for the current faction (matching Phoenix)
    let engineer_unit_id = match faction {
        Faction::Uef => "UEL0105",
        Faction::Cybran => "URL0105",
        Faction::Aeon => "UAL0105",
        Faction::Seraphim => "XSL0105",
    };
    
    // Find the base unit (T1 engineer) for the current faction
    let base_unit = all_units
        .iter()
        .find(|u| u.unit_id == engineer_unit_id)
        .cloned();
    
    // Get selected unit IDs from state
    let selected_unit_ids = (state.eco_selected_unit_ids)();
    
    // Get selected units as full Unit objects
    let selected_units: Vec<Unit> = all_units
        .iter()
        .filter(|u| selected_unit_ids.contains(&u.unit_id))
        .cloned()
        .collect();
    
    // Filters state - list of active filter keys (matching Phoenix)
    let mut active_filters = state.eco_active_filters;
    let filters_state = active_filters();
    
    // Get base unit ID for unit grid
    let base_unit_id = base_unit.as_ref().map(|u| u.unit_id.clone());
    let base_unit_id_for_toggle = base_unit_id.clone();

    // Handle unit toggle
    let toggle_unit = move |unit: Unit| {
        // Don't allow toggling the base unit
        if let Some(ref base_id) = base_unit_id_for_toggle {
            if unit.unit_id == *base_id {
                return;
            }
        }
        state.toggle_unit_selection(unit.unit_id);
    };
    
    // Handle clear selections
    let clear_selections = move |_| {
        state.clear_unit_selections();
    };
    
    // Handle filter toggle (matching Phoenix's toggle_filter behavior)
    let toggle_filter = move |filter_key: String| {
        let current = active_filters();
        if current.contains(&filter_key) {
            // Remove filter if already active
            active_filters.set(current.into_iter().filter(|f| f != &filter_key).collect());
        } else {
            // Add new filter
            let mut new_filters = current;
            new_filters.push(filter_key);
            active_filters.set(new_filters);
        }
    };
    
    // Handle clear all filters
    let on_clear_filters = move |_| {
        active_filters.set(vec![]);
    };

    rsx! {
        div { class: "min-h-screen flex flex-col",
            Header {}
            main { class: "flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6",
                // Header section
                div { class: "mb-6",
                    h1 { class: "text-3xl font-bold text-gray-900", "Eco Guides" }
                    p { class: "mt-2 text-gray-600",
                        "Select units to compare their economy costs against the faction's T1 Engineer."
                    }
                }
                
                // Faction tabs
                div { class: "mb-6",
                    FactionTabs {
                        selected_faction: faction,
                        on_select: move |f| state.selected_faction.set(Some(f)),
                    }
                }
                
                // Main content: 8+4 column layout
                div { class: "grid grid-cols-1 lg:grid-cols-12 gap-6",
                    // Left column (8): Unit Selection with integrated filters
                    div { class: "lg:col-span-8 space-y-6",
                        // Base Unit Card (Engineer)
                        BaseUnitCard {
                            base_unit: base_unit.clone(),
                            selected_faction: faction,
                        }
                        
                        // Unit Grid with integrated filters - single card
                        UnitGrid {
                            units: all_units.clone(),
                            selected_faction: faction,
                            selected_unit_ids: selected_unit_ids.to_vec(),
                            base_unit_id: base_unit_id.clone(),
                            on_toggle_unit: toggle_unit,
                            on_clear_selections: clear_selections,
                            // Filter props (simplified to match Phoenix)
                            active_filters: filters_state.clone(),
                            on_toggle_filter: toggle_filter,
                            on_clear_filters: on_clear_filters,
                        }
                    }
                    
                    // Right column (4): Eco Comparison
                    div { class: "lg:col-span-4 space-y-4",
                        if let Some(ref base) = base_unit {
                            EcoComparison {
                                base_unit: base.clone(),
                                selected_units: selected_units.clone(),
                            }
                        } else {
                            div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
                                p { class: "text-gray-500 text-center", "No base unit found for this faction." }
                            }
                        }
                    }
                }
            }
        }
    }
}
