use dioxus::prelude::*;
use fafcn_core::{Faction, Unit};

#[derive(Props, Clone, PartialEq)]
pub struct UnitCardProps {
    pub unit: Unit,
    pub is_selected: bool,
    pub is_disabled: bool,
    pub is_base_unit: bool,
    pub on_click: EventHandler<Unit>,
}

fn get_faction_bg_class(faction: Faction) -> &'static str {
    match faction {
        Faction::Uef => "unit-bg-uef",
        Faction::Cybran => "unit-bg-cybran",
        Faction::Aeon => "unit-bg-aeon",
        Faction::Seraphim => "unit-bg-seraphim",
    }
}

#[component]
pub fn UnitCard(props: UnitCardProps) -> Element {
    let faction_bg = get_faction_bg_class(props.unit.faction);
    let unit_icon_class = format!("unit-icon-{}", props.unit.unit_id);

    // Base unit (engineer) - cannot be deselected, has yellow star
    let is_base = props.is_base_unit;
    
    // Card selection styles
    let border_class = if props.is_selected {
        "ring-2 ring-indigo-500 ring-offset-1"
    } else if is_base {
        "ring-2 ring-yellow-400 ring-offset-1 cursor-default"
    } else {
        "hover:ring-2 hover:ring-gray-300 hover:ring-offset-1 cursor-pointer"
    };

    let cursor_class = if props.is_disabled && !props.is_selected && !is_base {
        "cursor-default opacity-50"
    } else {
        ""
    };

    rsx! {
        button {
            class: "group relative aspect-square rounded-lg p-1 transition-all duration-150 flex flex-col items-center justify-center text-center overflow-hidden {faction_bg} {border_class} {cursor_class}",
            title: "{props.unit.description.clone().unwrap_or_default()}",
            onclick: move |_| {
                if !props.is_disabled || props.is_selected || is_base {
                    props.on_click.call(props.unit.clone());
                }
            },
            disabled: props.is_disabled && !props.is_selected && !is_base,
            
            // Unit icon from sprite sheet
            div { class: "{unit_icon_class} w-12 h-12 shrink-0" }
            
            // Yellow star for base unit
            if is_base {
                span { class: "absolute -top-1 -right-1 w-4 h-4 bg-yellow-400 rounded-full flex items-center justify-center z-10",
                    span { class: "text-[8px] font-bold text-yellow-900", "★" }
                }
            }
            
            // Indigo checkmark for selected units
            if props.is_selected {
                span { class: "absolute -top-1 -right-1 w-4 h-4 bg-indigo-500 rounded-full flex items-center justify-center z-10",
                    // Checkmark SVG
                    svg {
                        class: "w-3 h-3 text-white",
                        view_box: "0 0 20 20",
                        fill: "currentColor",
                        path {
                            fill_rule: "evenodd",
                            d: "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z",
                            clip_rule: "evenodd"
                        }
                    }
                }
            }
        }
    }
}
