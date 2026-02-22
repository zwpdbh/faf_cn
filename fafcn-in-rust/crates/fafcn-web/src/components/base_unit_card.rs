use dioxus::prelude::*;
use fafcn_core::{Faction, Unit};

#[derive(Props, Clone, PartialEq)]
pub struct BaseUnitCardProps {
    pub base_unit: Option<Unit>,
    pub selected_faction: Faction,
}

fn get_faction_badge_class(faction: Faction) -> &'static str {
    match faction {
        Faction::Uef => "bg-blue-100 text-blue-800",
        Faction::Cybran => "bg-red-100 text-red-800",
        Faction::Aeon => "bg-emerald-100 text-emerald-800",
        Faction::Seraphim => "bg-violet-100 text-violet-800",
    }
}

fn get_faction_bg_class(faction: Faction) -> &'static str {
    match faction {
        Faction::Uef => "unit-bg-uef",
        Faction::Cybran => "unit-bg-cybran",
        Faction::Aeon => "unit-bg-aeon",
        Faction::Seraphim => "unit-bg-seraphim",
    }
}

fn get_tech_badge(unit: &Unit) -> String {
    let categories = &unit.categories;
    if categories.contains(&"TECH1".to_string()) {
        "T1".to_string()
    } else if categories.contains(&"TECH2".to_string()) {
        "T2".to_string()
    } else if categories.contains(&"TECH3".to_string()) {
        "T3".to_string()
    } else if categories.contains(&"EXPERIMENTAL".to_string()) {
        "EXP".to_string()
    } else {
        "T1".to_string()
    }
}

fn format_number(n: i32) -> String {
    if n >= 1000 {
        format!("{:.1}k", n as f64 / 1000.0)
    } else {
        n.to_string()
    }
}

fn format_unit_display_name(unit: &Unit) -> String {
    unit.description.clone()
        .or_else(|| unit.name.clone())
        .unwrap_or_else(|| unit.unit_id.clone())
}

#[component]
pub fn BaseUnitCard(props: BaseUnitCardProps) -> Element {
    let faction_badge = get_faction_badge_class(props.selected_faction);
    let faction_name = format!("{}", props.selected_faction);

    rsx! {
        div { class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4",
            div { class: "flex items-center justify-between mb-3",
                h2 { class: "text-lg font-semibold text-gray-900", "Base Unit (Engineer)" }
                span { class: "px-2 py-1 text-xs font-medium rounded-full {faction_badge}",
                    {faction_name}
                }
            }
            
            if let Some(ref unit) = props.base_unit {
                div { class: "flex items-center space-x-4",
                    // Engineer Icon
                    div { class: "w-16 h-16 rounded-lg flex items-center justify-center shadow-inner {get_faction_bg_class(unit.faction)}",
                        div { class: "unit-icon-{unit.unit_id} w-14 h-14" }
                    }
                    div { class: "flex-1",
                        div { class: "flex items-center space-x-2",
                            span { class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800",
                                {get_tech_badge(unit)}
                            }
                            h3 { class: "font-semibold text-gray-900", {unit.unit_id.clone()} }
                        }
                        p { class: "text-sm text-gray-600",
                            {format_unit_display_name(unit)}
                        }
                        div { class: "mt-1 flex items-center space-x-4 text-xs text-gray-500",
                            span { "Mass: {format_number(unit.build_cost_mass)}" }
                            span { "Energy: {format_number(unit.build_cost_energy)}" }
                            span { "BT: {format_number(unit.build_time)}" }
                        }
                    }
                }
            }
        }
    }
}
