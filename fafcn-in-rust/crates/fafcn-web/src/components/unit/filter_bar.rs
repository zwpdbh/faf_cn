use dioxus::prelude::*;
use fafcn_core::{TechLevel, UnitCategory};

#[derive(Props, Clone, PartialEq)]
pub struct FilterBarProps {
    pub tech_levels: Vec<TechLevel>,
    pub selected_tech_level: Option<TechLevel>,
    pub on_select_tech: EventHandler<Option<TechLevel>>,
    
    pub categories: Vec<UnitCategory>,
    pub selected_category: Option<UnitCategory>,
    pub on_select_category: EventHandler<Option<UnitCategory>>,
    
    pub search_query: String,
    pub on_search: EventHandler<String>,
    
    #[props(default = Callback::new(|_| ()))]
    pub on_clear_filters: EventHandler<()>,
}

#[component]
pub fn FilterBar(props: FilterBarProps) -> Element {
    // Check if any filters are active
    let has_active_filters = props.selected_tech_level.is_some() 
        || props.selected_category.is_some() 
        || !props.search_query.is_empty();

    rsx! {
        div { class: "flex flex-wrap gap-2 mb-2",
            // Tech level filter buttons
            {
                let tech_options: Vec<(Option<TechLevel>, &str)> = vec![
                    (None, "All Tech"),
                    (Some(TechLevel::T1), "T1"),
                    (Some(TechLevel::T2), "T2"),
                    (Some(TechLevel::T3), "T3"),
                    (Some(TechLevel::Experimental), "EXP"),
                ];
                
                tech_options.into_iter().map(|(tech, label)| {
                    let is_active = props.selected_tech_level == tech;
                    let btn_class = if is_active {
                        "px-3 py-1.5 rounded text-sm font-medium transition-all bg-indigo-500 text-white shadow-md"
                    } else {
                        "px-3 py-1.5 rounded text-sm font-medium transition-all bg-white/90 text-gray-700 hover:bg-white hover:shadow"
                    };
                    
                    rsx! {
                        button {
                            class: btn_class,
                            onclick: move |_| props.on_select_tech.call(tech),
                            {label}
                        }
                    }
                })
            }
            
            // Clear all button
            if has_active_filters {
                button {
                    class: "px-3 py-1.5 rounded text-sm font-medium bg-gray-500/50 text-white hover:bg-gray-500/70 transition-all",
                    onclick: move |_| props.on_clear_filters.call(()),
                    "Clear All"
                }
            }
        }
        
        // Category filters row
        div { class: "flex flex-wrap gap-2",
            {
                let cat_options: Vec<(Option<UnitCategory>, &str)> = vec![
                    (None, "All"),
                    (Some(UnitCategory::Engineer), "Engineer"),
                    (Some(UnitCategory::Structure), "Structure"),
                    (Some(UnitCategory::Land), "Land"),
                    (Some(UnitCategory::Air), "Air"),
                    (Some(UnitCategory::Naval), "Naval"),
                ];
                
                cat_options.into_iter().map(|(cat, label)| {
                    let is_active = props.selected_category == cat;
                    let btn_class = if is_active {
                        "px-3 py-1.5 rounded text-sm font-medium transition-all bg-indigo-500 text-white shadow-md"
                    } else {
                        "px-3 py-1.5 rounded text-sm font-medium transition-all bg-white/90 text-gray-700 hover:bg-white hover:shadow"
                    };
                    
                    rsx! {
                        button {
                            class: btn_class,
                            onclick: move |_| props.on_select_category.call(cat),
                            {label}
                        }
                    }
                })
            }
        }
        
        // Search input
        div { class: "mt-2",
            input {
                class: "w-full px-3 py-2 text-sm border border-gray-200 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500",
                placeholder: "Search units by name or unit ID...",
                value: props.search_query.clone(),
                oninput: move |e| props.on_search.call(e.value().clone()),
            }
        }
    }
}
