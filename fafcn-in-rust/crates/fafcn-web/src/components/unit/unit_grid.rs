use dioxus::prelude::*;
use fafcn_core::{Faction, Unit};

use super::unit_card::UnitCard;

/// Filter definition matching Phoenix structure
#[derive(Clone, PartialEq)]
pub struct FilterDef {
    pub key: &'static str,
    pub label: &'static str,
    pub group: FilterGroup,
}

#[derive(Clone, PartialEq)]
pub enum FilterGroup {
    Usage,
    Tech,
}

#[derive(Props, Clone, PartialEq)]
pub struct UnitGridProps {
    pub units: Vec<Unit>,
    pub selected_faction: Faction,
    pub selected_unit_ids: Vec<String>,
    pub base_unit_id: Option<String>,
    pub on_toggle_unit: EventHandler<Unit>,
    #[props(default = Callback::new(|_| ()))]
    pub on_clear_selections: EventHandler<()>,
    // Active filter keys (like Phoenix's active_filters list)
    #[props(default = vec![])]
    pub active_filters: Vec<String>,
    #[props(default = Callback::new(|_| ()))]
    pub on_toggle_filter: EventHandler<String>,
    #[props(default = Callback::new(|_| ()))]
    pub on_clear_filters: EventHandler<()>,
    #[props(default = String::new())]
    pub search_query: String,
}

#[component]
pub fn UnitGrid(props: UnitGridProps) -> Element {
    // Define available filters (matching Phoenix)
    let filters = vec![
        FilterDef { key: "ENGINEER", label: "Engineer", group: FilterGroup::Usage },
        FilterDef { key: "STRUCTURE", label: "Structure", group: FilterGroup::Usage },
        FilterDef { key: "LAND", label: "Land", group: FilterGroup::Usage },
        FilterDef { key: "AIR", label: "Air", group: FilterGroup::Usage },
        FilterDef { key: "NAVAL", label: "Naval", group: FilterGroup::Usage },
        FilterDef { key: "TECH1", label: "T1", group: FilterGroup::Tech },
        FilterDef { key: "TECH2", label: "T2", group: FilterGroup::Tech },
        FilterDef { key: "TECH3", label: "T3", group: FilterGroup::Tech },
        FilterDef { key: "EXPERIMENTAL", label: "EXP", group: FilterGroup::Tech },
    ];

    // Filter and sort units by unit_id (matching Phoenix logic)
    let mut filtered_units: Vec<Unit> = props.units
        .into_iter()
        .filter(|u| u.faction == props.selected_faction)
        .filter(|u| {
            // Search filter
            if !props.search_query.is_empty() {
                let query = props.search_query.to_lowercase();
                let matches_search = u.unit_id.to_lowercase().contains(&query)
                    || u.name.as_ref().map(|n| n.to_lowercase().contains(&query)).unwrap_or(false)
                    || u.description.as_ref().map(|d| d.to_lowercase().contains(&query)).unwrap_or(false);
                if !matches_search {
                    return false;
                }
            }
            
            // Category filters - all active filters must match (AND logic)
            // This matches Phoenix's apply_filters behavior
            for filter_key in &props.active_filters {
                if !u.categories.iter().any(|c| c == filter_key) {
                    return false;
                }
            }
            
            true
        })
        .collect();
    
    // Sort by unit_id to have consistent ordering (matching Phoenix)
    filtered_units.sort_by(|a, b| a.unit_id.cmp(&b.unit_id));

    let selected_count = props.selected_unit_ids.len();
    let has_selections = selected_count > 0;
    let has_filters = !props.active_filters.is_empty() || !props.search_query.is_empty();

    rsx! {
        div {
            class: "rounded-lg shadow-sm border border-gray-200 p-4",
            style: "background-image: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.3)), url('/assets/images/units/background.jpg'); background-size: cover; background-position: center;",
            
            // Header with title and clear button
            div { class: "flex items-center justify-between mb-4",
                h2 { class: "text-lg font-semibold text-white drop-shadow-md",
                    "Select Units to Compare"
                }
                
                if has_selections {
                    button {
                        class: "text-sm bg-red-600 hover:bg-red-700 text-white px-3 py-1.5 rounded-lg transition-colors shadow-md font-medium",
                        onclick: move |_| props.on_clear_selections.call(()),
                        "Clear (" {selected_count.to_string()} ")"
                    }
                }
            }
            
            // Filter Bar
            div { class: "flex flex-wrap gap-2 mb-4",
                // Filter buttons - matching Phoenix behavior
                for filter in filters {
                    {
                        let filter_key = filter.key.to_string();
                        let is_active = props.active_filters.contains(&filter_key);
                        rsx! {
                            button {
                                class: if is_active {
                                    "px-3 py-1.5 rounded text-sm font-medium transition-all bg-indigo-500 text-white shadow-md"
                                } else {
                                    "px-3 py-1.5 rounded text-sm font-medium transition-all bg-white/90 text-gray-700 hover:bg-white hover:shadow"
                                },
                                onclick: move |_| {
                                    props.on_toggle_filter.call(filter_key.clone());
                                },
                                {filter.label}
                            }
                        }
                    }
                }
                
                // Clear all filters button
                if has_filters {
                    button {
                        class: "px-3 py-1.5 rounded text-sm font-medium bg-gray-500/50 text-white hover:bg-gray-500/70 transition-all",
                        onclick: move |_| props.on_clear_filters.call(()),
                        "Clear All"
                    }
                }
            }
            
            // Unit Grid
            if filtered_units.is_empty() {
                div { class: "text-center py-8 text-white/70",
                    p { class: "text-lg", "No units match the selected filters." }
                    button {
                        class: "mt-4 text-sm underline hover:text-white px-3 py-1",
                        onclick: move |_| props.on_clear_filters.call(()),
                        "Clear filters"
                    }
                }
            } else {
                div { class: "grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-3",
                    for unit in filtered_units {
                        {
                            let is_selected = props.selected_unit_ids.contains(&unit.unit_id);
                            let is_base = props.base_unit_id.as_ref() == Some(&unit.unit_id);
                            
                            rsx! {
                                UnitCard {
                                    unit: unit.clone(),
                                    is_selected: is_selected,
                                    is_disabled: false,
                                    is_base_unit: is_base,
                                    on_click: props.on_toggle_unit.clone(),
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
