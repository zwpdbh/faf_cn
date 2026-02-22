use dioxus::prelude::*;
use fafcn_core::{Faction, Unit};

use super::unit_card::UnitCard;

#[derive(Props, Clone, PartialEq)]
pub struct UnitGridProps {
    pub units: Vec<Unit>,
    pub selected_faction: Faction,
    pub selected_unit_ids: Vec<String>,
    pub base_unit_id: Option<String>,
    pub on_toggle_unit: EventHandler<Unit>,
    #[props(default = Callback::new(|_| ()))]
    pub on_clear_selections: EventHandler<()>,
}

#[component]
pub fn UnitGrid(props: UnitGridProps) -> Element {
    // Filter units by selected faction
    let filtered_units: Vec<Unit> = props.units
        .into_iter()
        .filter(|u| u.faction == props.selected_faction)
        .collect();

    let selected_count = props.selected_unit_ids.len();

    rsx! {
        div {
            class: "rounded-lg shadow-sm border border-gray-200 p-4",
            style: "background-image: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.3)), url('/images/units/background.jpg'); background-size: cover; background-position: center;",
            
            // Header with title and clear button
            div { class: "flex items-center justify-between mb-4",
                h2 { class: "text-lg font-semibold text-white drop-shadow-md",
                    "Select Units to Compare"
                }
                
                if selected_count > 0 {
                    button {
                        class: "text-sm bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded transition-colors shadow-md",
                        onclick: move |_| props.on_clear_selections.call(()),
                        "Clear ({selected_count})"
                    }
                }
            }
            
            // Unit Grid
            if filtered_units.is_empty() {
                div { class: "text-center py-8 text-white/70",
                    p { "No units match the selected filters." }
                    button {
                        class: "mt-2 text-sm underline hover:text-white",
                        onclick: move |_| {},
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
