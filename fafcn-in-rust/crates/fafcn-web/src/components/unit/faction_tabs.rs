use dioxus::prelude::*;
use fafcn_core::Faction;

#[derive(Props, Clone, PartialEq)]
pub struct FactionTabsProps {
    pub selected_faction: Faction,
    pub on_select: EventHandler<Faction>,
}

#[component]
pub fn FactionTabs(props: FactionTabsProps) -> Element {
    let factions = vec![
        (Faction::Uef, "UEF", "blue-500", "blue-600"),
        (Faction::Cybran, "CYBRAN", "red-500", "red-600"),
        (Faction::Aeon, "AEON", "emerald-500", "emerald-600"),
        (Faction::Seraphim, "SERAPHIM", "violet-500", "violet-600"),
    ];

    rsx! {
        div { class: "border-b border-gray-200",
            nav { class: "-mb-px flex space-x-8", "aria-label": "Tabs",
                for (faction, name, active_border, active_text) in factions {
                    {
                        let is_active = props.selected_faction == faction;
                        let border_class = if is_active {
                            format!("border-{} text-{}", active_border, active_text)
                        } else {
                            "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300".to_string()
                        };
                        
                        rsx! {
                            button {
                                class: "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm capitalize transition-colors {border_class}",
                                onclick: move |_| props.on_select.call(faction),
                                {name}
                            }
                        }
                    }
                }
            }
        }
    }
}
