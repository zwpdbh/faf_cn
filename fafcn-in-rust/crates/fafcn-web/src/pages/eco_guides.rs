use dioxus::prelude::*;
use fafcn_core::Faction;

use crate::{
    state::use_app_state,
    components::{Header, faction_tabs::FactionTabs, filter_bar::FilterBar, unit_grid::UnitGrid},
    data::get_all_units,
};

#[component]
pub fn EcoGuides() -> Element {
    let mut state = use_app_state();
    let mut filters = state.active_filters;
    
    let selected_faction = (state.selected_faction)();
    let faction = selected_faction.unwrap_or(Faction::Uef);
    
    let all_units = get_all_units();
    
    // Filter units locally
    let filtered_units: Vec<_> = all_units
        .iter()
        .filter(|u| u.faction == faction)
        .filter(|u| {
            let f = filters();
            if f.search.is_empty() {
                true
            } else {
                let query = f.search.to_lowercase();
                u.unit_id.to_lowercase().contains(&query)
                    || u.name.as_ref().map(|n| n.to_lowercase().contains(&query)).unwrap_or(false)
            }
        })
        .cloned()
        .collect();
    
    // Get selected unit IDs from state
    let selected_units: Vec<String> = vec![]; // Would come from selected units state
    let base_unit_id: Option<String> = None; // Would be the T1 engineer

    rsx! {
        div { class: "min-h-screen flex flex-col",
            Header {}
            main { class: "flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6",
            div { class: "mb-6",
                h1 { class: "text-3xl font-bold text-gray-900", "Eco Guides" }
                p { class: "mt-2 text-gray-600",
                    "View unit costs and build times by faction."
                }
            }
            
            FactionTabs {
                selected_faction: faction,
                on_select: move |f| state.selected_faction.set(Some(f)),
            }
            
            // Filters
            div { class: "mt-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4",
                FilterBar {
                    tech_levels: vec![],
                    selected_tech_level: None,
                    on_select_tech: move |_| {},
                    categories: vec![],
                    selected_category: None,
                    on_select_category: move |_| {},
                    search_query: filters().search.clone(),
                    on_search: move |query| {
                        filters.write().search = query;
                    },
                    on_clear_filters: move |_| {
                        filters.write().search = String::new();
                    },
                }
                
                div { class: "mt-4",
                    UnitGrid {
                        units: filtered_units,
                        selected_faction: faction,
                        selected_unit_ids: selected_units,
                        base_unit_id: base_unit_id,
                        on_toggle_unit: move |unit| {
                            state.selected_unit.set(Some(unit));
                        },
                        on_clear_selections: move |_| {
                            // Clear selections
                        },
                    }
                }
            }
            }
        }
    }
}
