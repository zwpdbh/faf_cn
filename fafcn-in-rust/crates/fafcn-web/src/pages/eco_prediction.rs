use dioxus::prelude::*;
use fafcn_core::{Faction, TechLevel, UnitCategory};

use crate::{
    state::{use_app_state, FilterState},
    components::{
        Header,
        faction_tabs::FactionTabs,
        filter_bar::FilterBar,
        unit_grid::UnitGrid,
        eco_inputs::EcoInputs,
        build_queue::BuildQueue,
        eco_summary::EcoSummary,
    },
    data::get_all_units,
};

#[component]
pub fn EcoPrediction() -> Element {
    let mut state = use_app_state();
    
    // Local filter state
    let mut filter_state = use_signal(|| FilterState {
        search: String::new(),
        tech_level: None,
        category: None,
    });
    
    let units = get_all_units();
    
    // Get current state values
    let selected_faction = (state.selected_faction)();
    let faction = selected_faction.unwrap_or(Faction::Uef);
    
    // Filtered units based on search and filters
    let filtered_units: Vec<_> = units
        .iter()
        .filter(|u| u.faction == faction)
        .filter(|u| {
            if filter_state().search.is_empty() {
                true
            } else {
                let query = filter_state().search.to_lowercase();
                u.unit_id.to_lowercase().contains(&query)
                    || u.name.as_ref().map(|n| n.to_lowercase().contains(&query)).unwrap_or(false)
            }
        })
        .cloned()
        .collect();
    
    // Tech levels and categories for filter counts
    let tech_levels: Vec<TechLevel> = vec![
        TechLevel::T1, TechLevel::T2, TechLevel::T3, TechLevel::Experimental
    ];
    
    let categories: Vec<UnitCategory> = vec![
        UnitCategory::Engineer, UnitCategory::Structure, 
        UnitCategory::Land, UnitCategory::Air, UnitCategory::Naval
    ];

    rsx! {
        div { class: "min-h-screen flex flex-col",
            Header {}
            main { class: "flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6",
            // Page Header
            div { class: "mb-6",
                h1 { class: "text-3xl font-bold text-gray-900", "Eco Prediction" }
                p { class: "mt-2 text-gray-600",
                    "Calculate how long it takes to afford your target units."
                }
            }
            
            // Faction Tabs
            div { class: "mb-6",
                FactionTabs {
                    selected_faction: faction,
                    on_select: move |f| state.selected_faction.set(Some(f)),
                }
            }
            
            // Main content: 8 + 4 column layout
            div { class: "grid grid-cols-1 lg:grid-cols-12 gap-6",
                
                // Left column (8 cols): Eco Inputs + Unit Selection
                div { class: "lg:col-span-8 space-y-6",
                    
                    // 1. Set Initial Eco
                    div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
                        h2 { class: "text-base font-semibold text-gray-900 mb-4",
                            "1. Set Initial Eco"
                        }
                        EcoInputs {}
                    }
                    
                    // 2. Select Units
                    div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
                        h2 { class: "text-base font-semibold text-gray-900 mb-4",
                            "2. Select Units to Build"
                        }
                        
                        // Filters
                        div { class: "mb-4 space-y-2",
                            FilterBar {
                                tech_levels: tech_levels.clone(),
                                selected_tech_level: filter_state().tech_level,
                                on_select_tech: move |tech| {
                                    filter_state.write().tech_level = tech;
                                },
                                categories: categories.clone(),
                                selected_category: filter_state().category,
                                on_select_category: move |cat| {
                                    filter_state.write().category = cat;
                                },
                                search_query: filter_state().search.clone(),
                                on_search: move |query| {
                                    filter_state.write().search = query;
                                },
                                on_clear_filters: move |_| {
                                    filter_state.write().tech_level = None;
                                    filter_state.write().category = None;
                                    filter_state.write().search = String::new();
                                },
                            }
                        }
                        
                        // Unit Grid
                        UnitGrid {
                            units: filtered_units,
                            selected_faction: faction,
                            selected_unit_ids: vec![],
                            base_unit_id: None,
                            on_toggle_unit: move |unit| {
                                crate::state::add_to_queue(state, unit, 1);
                            },
                            on_clear_selections: move |_| {
                                // Clear build queue
                                crate::state::clear_queue(state);
                            },
                        }
                    }
                }
                
                // Right column (4 cols): Goal + Timeline
                div { class: "lg:col-span-4 space-y-4",
                    // Build Queue
                    BuildQueue {}
                    
                    // Eco Summary / Results
                    EcoSummary {}
                }
            }
            }
        }
    }
}
